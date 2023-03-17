#!/usr/bin/env perl
use v5.12;
use utf8;
use warnings;
use open qw(:std :utf8);
use File::Basename;
use lib dirname (__FILE__);

use Mojolicious::Lite;
use Mojo::Util;
use Mojo::JWT;
use Database;

my $root_uri = "http://172.27.114.79:3000";

# FIXME: 写一个真正的哈希函数
sub _hash {
    my $text = shift;
    length $text;
}

helper db => (
    sub {
        my $db = Database->new();
        sub { $db };
    }
)->();

helper logined_user_id => sub {
    my $c = shift;
    my $session_id = $c->session->{session_id};
    $c->db->get_uid_by_session($session_id);
};

helper expect => sub {
    my ($c, $var, @err) = @_;
    $c->render(@err) unless defined $var;
    $var
};

helper assert => sub {
    my ($c, $cond, @err) = @_;
    if ($cond) {
        $cond
    } else {
        $c->render(@err);
        undef
    }
};

get '/debug/kill/:uid' => sub {
};

# 用户的首页，好像没要求
# 哦，要求了。后面还要收藏番剧
get '/user/query/:uid' => sub {
    ...
};

# 登录
get '/user/login' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $password = _hash($c->param('password'));

    $c->expect(
        $name,
        text => "你要提供用户名",
        status => 400,
    ) // return;

    $c->expect(
        $password,
        text => "你要提供密码",
        status => 400,
    ) // return;

    my $uid = $c->expect(
        $c->db->get_uid_by_name($name),
        text => "没有这个用户",
        status => 404,
    ) // return;

    my $user = $c->expect(
        $c->db->get_user($uid),
        text => "有这个用户但是找不到，数据库坏掉了？",
        status => 500,
    ) // return;

    $c->assert(
        $password eq $user->{password},
        text => "密码不对",
        status => 403,
    ) // return;

    # FIXME
    my $session_id = time;

    $c->expect(
        $c->db->new_session(
            uid => $uid,
            id => $session_id,
        ),
        text => "没法新建会话，数据库出问题了",
        status => 500,
    ) // return;

    $c->session->{session_id} = $session_id;

    $c->render(text => "登录成功\n");
};

# 邮箱验证
get '/user/verify_email' => sub {
    ...
};

# 从 bangumi 偷数据
get '/steal_data_from_bangumi' => sub {
    ...
};

# 各种回调函数，不过估计只有 bangumi 小偷会用到
post '/callback/:type/:id' => sub {
    ...
};

# 新建用户
post '/user/new' => sub {
    my ($c) = @_;

    # FIXME
    my $uid = time;

    $c->expect(
        $c->param('name'),
        text => "你要提供用户名",
        status => 400,
    ) // return;

    $c->expect(
        $c->param('password'),
        text => "你要提供密码",
        status => 400,
    ) // return;

    $c->assert(
        ! $c->db->has_user_name($c->param('name')),
        text => "用户名已经有人用了",
        status => 403,
    ) // return;

    $c->expect(
        $c->db->new_user(
            id => $uid,
            name => $c->param('name'),
            password => _hash($c->param('password')),
            email => $c->param('email'),
            nickname => $c->param('nickname'),
            description =>  $c->param('description'),
        ),
        text => "新建用户失败了",
        status => 500,
    ) // return;

    $c->render(text => "好力\n");
};

# 上传用户头像……怎么做
post '/user/upload_avantar' => sub {
    ...
};

# 删除用户
post '/user/drop' => sub {
    my $c = shift;
    ...
};

# 全量更新用户信息
put '/user/replace' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    $c->expect(
        $c->param('name'),
        text => "你要提供用户名",
        status => 400,
    ) // return;

    $c->expect(
        $c->param('password'),
        text => "你要提供密码",
        status => 400,
    ) // return;

    $c->expect(
        $c->db->replace_user(
            id => $uid,
            name => $c->param('name'),
            password => _hash($c->param('password')),
            email => $c->param('email'),
            nickname => $c->param('nickname'),
            description =>  $c->param('description'),
        ),
        text => "没法更新，数据库好像坏掉了",
        status => 500,
    ) // return;

    $c->render(text => "好力\n");
};

# 差量更新用户信息
patch '/user/update' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    $c->expect(
        $c->db->update_user(
            id => $uid,
            name => $c->param('name'),
            password => _hash($c->param('password')),
            email => $c->param('email'),
            nickname => $c->param('nickname'),
            description =>  $c->param('description'),
        ),
        text => "没法更新，数据库好像坏掉了",
        status => 500,
    ) // return;

    $c->render(text => "好力\n");
};

# oauth，首先在这里得到一个页面，同时验证用户正是本人……
get '/auth/authorize' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    $c->expect(
        $c->param('response_type'),
        text => "你要提供验证类型",
        status => 400,
    ) // return;

    $c->assert(
        $c->param('response_type') eq 'code',
        text => "只支持 code 类型的验证",
        status => 400,
    ) // return;

    $c->expect(
        $c->param('redirect_uri'),
        text => "你要提供回调链接",
        status => 400,
    ) // return;

    $c->expect(
        $c->param('scope'),
        text => "你要提供申请的权限",
        status => 400,
    ) // return;

    $c->expect(
        $c->param('client_id'),
        text => "你要提供客户端 id",
        status => 400,
    ) // return;

    # FIXME
    my $auth_id = time;

    $c->expect(
        $c->db->new_auth_request(
            id => $auth_id,
            uid => $uid,
            code => undef,

            response_type => $c->param('response_type'),
            client_id => $c->param('client_id'),
            redirect_uri => $c->param('redirect_uri'),
            scope => $c->param('scope'),
            state => $c->param('state'),
        ),
        text => "没法新建认证请求，数据库出问题了",
        status => 500,
    ) // return;

    my $client_id = $c->param('client_id');
    my $scope = $c->param('scope');
    $c->render(
        text => <<eof
有一个 $client_id 的客户端想要你的 $scope 权限
如果你同意的话就访问这个：/auth/confirm_authorize?id=$auth_id
eof
    );
};

# 然后用户点击神秘链接后再跳到这里，然后这里会调用第三方 app 提供的回调链接送出 code……
get '/auth/confirm_authorize' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    my $auth_id = $c->expect(
        $c->param('id'),
        text => "你要提供需要确认的身份请求的 id",
        status => 400,
    ) // return;

    my $auth = $c->expect(
        $c->db->get_auth($auth_id),
        text => "没有这个验证请求，你是不是在日我的网站？",
        status => 404,
    ) // return;

    $c->assert(
        $uid eq $auth->{uid},
        text => "这好像不是你的身份验证请求耶",
        status => 403,
    ) // return;

    # FIXME
    my $code = time;

    $c->expect(
        $c->db->set_auth_code(
            id => $auth_id,
            code => $code,
        ),
        text => "没法把 code 放到数据库里，坏掉了",
        status => 500,
    ) // return;

    my $uri = "$auth->{redirect_uri}?code=$code";
    $uri = "$uri&state=$auth->{state}" if defined $auth->{state};
    $uri = Mojo::Util::url_escape $uri;
    $c->redirect_to($uri);
};

helper give_token => sub {
    my ($c) = @_;

    $c->expect(
        $c->param('client_id'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    $c->expect(
        $c->param('code'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    $c->expect(
        $c->param('redirect_uri'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    $c->assert(
        $c->param('grant_type') eq 'authorization_code',
        status => 400,
        json => { error => 'unsupported_grant_type' },
    ) // return;

    my $auth_id = $c->expect(
        $c->db->get_auth_id_by_code($c->param('code')),
        status => 400,
        json => { error => 'invalid_grant' }
    ) // return;

    my $auth = $c->expect(
        $c->db->get_auth($auth_id),
        status => 500,
        text => "数据库烂掉了",
    ) // return;

    $c->assert(
        $c->param('redirect_uri') eq $auth->{redirect_uri},
        status => 400,
        json => { error => 'invalid_grant' }
    ) // return;

    # FIXME
    my $token_id = time;

    my $oidc_token = undef;
    if (grep { $_ eq 'openid' } split ' ', $auth->{scope}) {
        $oidc_token = Mojo::JWT->new(
            claims => {
                iss => $root_uri,
                sub => $auth->{uid},
                aud => $auth->{client_id},
                exp => time + 3600,
                iat => time,
                auth_time => time,
            },

            # FIXME
            secret => 'TEST',
        )->encode;
    };

    # FIXME: 这些玩意都是什么意思啊
    $c->expect(
        $c->db->new_token(
            id => $token_id,
            uid => $auth->{uid},
            redirect_uri => $auth->{redirect_uri},

            access_token => time,
            token_type => "bearer",
            expires_in => 3600,
            refresh_token => time,
            scope => $auth->{scope},

            id_token => $oidc_token,
        ),
        text => "新建 token 失败了，数据库烂掉了",
        status => 500,
    ) // return;

    $c->expect(
        $c->db->drop_auth($auth_id),
        text => "没法删除认证请求，数据库烂掉了",
        status => 500,
    ) // return;

    my $response = $c->expect(
        $c->db->get_token_response($token_id),
        text => "数据库坏掉了",
        status => 500,
    ) // return;

    $c->ua->post(
        $auth->{redirect_uri},
        => json => $response
        => sub {}
    );

    $c->render(text => '好力');
};

helper refresh_token => sub {
    my $c = shift;

    $c->assert(
        $c->param('grant_type') eq 'refresh_token',
        status => 400,
        json => { error => 'unsupported_grant_type' },
    ) // return;

    $c->expect(
        $c->param('refresh_token'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    my $token_id = $c->expect(
        $c->db->get_token_id_by_refresh_token($c->param('refresh_token')),
        status => 404,
        json => { error => 'invalid_grant' }
    ) // return;

    # FIXME
    my $new_access_token = time;
    $c->expect(
        $c->db->set_access_token($token_id, $new_access_token),
        text => "数据库烂掉了",
        status => 500,
    ) // return;

    my $token = $c->expect(
        $c->db->get_token($token_id),
        text => "数据库坏掉了",
        status => 500,
    ) // return;

    my $response = $c->expect(
        $c->db->get_token_response($token_id),
        text => "数据库坏掉了",
        status => 500,
    ) // return;

    $c->ua->post(
        $token->{redirect_uri},
        => json => $response
        => sub {}
    );

    $c->render(text => '好力');
};

# 然后第三方 app 再用 code 在这里拿 token。
# 妈的，这个还要支持 refresh_token
post '/auth/token' => sub {
    my $c = shift;

    $c->assert(
        $c->param('grant_type'),
        status => 400,
        json => { error => 'invalid_request' }
    ) // return;

    if ($c->param('grant_type') eq 'refresh_token') {
        $c->refresh_token;
    } else {
        $c->give_token;
    }
};

get '/auth/userinfo' => sub {
    my $c = shift;

    my $access_token = $c->expect(
        $c->req->headers->header('Authorization'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    $access_token =~ s/^Bearer\s+//;

    my $token_id = $c->expect(
        $c->db->get_token_id_by_access_token($access_token),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    my $token = $c->expect(
        $c->db->get_token($token_id),
        status => 500,
        text => '数据库爆炸了！',
    ) // return;

    my $user = $c->db->get_user($token->{uid});

    my $response = {};
    $response->{sub} = $token->{uid};
    for (split ' ', $token->{scope}) {
        $response->{$_} = $user->{$_} if exists $user->{$_};
    }

    $c->render(json => $response);
};

get '/.well-known/openid-configuration' => sub {
    my $c = shift;
    $c->render(
        json => {
            issuer => $root_uri,
            authorization_endpoint => "$root_uri/auth/authorize",
            token_endpoint => "$root_uri/auth/token",
            userinfo_endpoint => "$root_uri/auth/userinfo",
        }
    );
};

app->start('daemon');
