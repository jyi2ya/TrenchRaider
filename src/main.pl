#!/usr/bin/env perl
use v5.12;
use utf8;
use warnings;
use open qw(:std :utf8);
use File::Basename;
use lib dirname (__FILE__);

use Mojolicious::Lite;
use Database;

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
    my ($c, $var, $errmsg) = @_;
    $c->render(text => "$errmsg\n") unless defined $var;
    $var
};

helper assert => sub {
    my ($c, $cond, $errmsg) = @_;
    if ($cond) {
        $cond
    } else {
        $c->render(text => "$errmsg\n");
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

    $c->expect($name, "你要提供用户名") // return;
    $c->expect($password, "你要提供密码") // return;
    my $uid = $c->expect(
        $c->db->get_uid_by_name($name),
        "没有这个用户",
    ) // return;
    my $user = $c->expect(
        $c->db->get_user($uid),
        "有这个用户但是找不到，数据库坏掉了？",
    ) // return;
    $c->assert(
        $password eq $user->{password},
        "密码不对"
    ) // return;

    # FIXME
    my $session_id = time;

    $c->expect(
        $c->db->new_session(
            uid => $uid,
            id => $session_id,
        ),
        "没法新建会话，数据库出问题了",
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

    $c->expect($c->param('name'), "你要提供用户名") // return;
    $c->expect($c->param('password'), "你要提供密码") // return;

    $c->assert(
        ! $c->db->has_user_name($c->param('name')),
        "用户名已经有人用了",
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
        "新建用户失败了",
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
        "好像还没登录",
    ) // return;

    $c->expect($c->param('name'), "你要提供用户名") // return;
    $c->expect($c->param('password'), "你要提供密码") // return;

    $c->expect(
        $c->db->replace_user(
            id => $uid,
            name => $c->param('name'),
            password => _hash($c->param('password')),
            email => $c->param('email'),
            nickname => $c->param('nickname'),
            description =>  $c->param('description'),
        ),
        "没法更新，数据库好像坏掉了",
    ) // return;

    $c->render(text => "好力\n");
};

# 差量更新用户信息
patch '/user/update' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        "好像还没登录",
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
        "没法更新，数据库好像坏掉了",
    ) // return;

    $c->render(text => "好力\n");
};

# oauth，首先在这里得到一个页面，同时验证用户正是本人……
get '/oauth/authorize' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        "好像还没登录",
    ) // return;

    $c->expect(
        $c->param('response_type'),
        "你要提供验证类型",
    ) // return;

    $c->assert(
        $c->param('response_type') eq 'code',
        "只支持 code 类型的验证",
    ) // return;

    $c->expect(
        $c->param('redirect_uri'),
        "你要提供回调链接",
    ) // return;

    $c->expect(
        $c->param('client_id'),
        "你要提供客户端 id",
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
        "没法新建认证请求，数据库出问题了",
    ) // return;

    $c->render(text => "访问这个链接：/oauth/confirm_authorize?id=$auth_id\n");
};

# 然后用户点击神秘链接后再跳到这里，然后这里会调用第三方 app 提供的回调链接送出 code……
get '/oauth/confirm_authorize' => sub {
    my ($c) = @_;

    my $uid = $c->expect(
        $c->logined_user_id,
        "好像还没登录",
    ) // return;

    my $auth_id = $c->expect(
        $c->param('id'),
        "你要提供需要确认的身份请求的 id",
    ) // return;

    my $auth = $c->expect(
        $c->db->get_auth($auth_id),
        "没有这个验证请求，你是不是在日我的网站？",
    ) // return;

    $c->assert(
        $uid eq $auth->{uid},
        "这好像不是你的身份验证请求耶",
    ) // return;

    # FIXME
    my $code = time;

    $c->expect(
        $c->db->set_auth_code(
            id => $auth_id,
            code => $code,
        ),
        "没法把 code 放到数据库里，坏掉了",
    ) // return;

    # FIXME: 没有 state 的时候就不要加上 state 啦
    $c->render(
        text => "然后访问这个链接：$auth->{redirect_uri}?code=$code&state=$auth->{state}\n"
    );
};

# 然后第三方 app 再用 code 在这里拿 token。
# 妈的，这个还要支持 refresh_token
get '/oauth/token' => sub {
    my ($c) = @_;

    $c->expect(
        $c->param('client_id'),
        "你要提供客户端 id",
    ) // return;

    $c->assert(
        $c->param('grant_type'),
        "你要提供你需要的认证方式",
    ) // return;

    $c->assert(
        $c->param('grant_type') eq 'authorization_code',
        "只支持 code 类型的认证",
    ) // return;

    $c->expect(
        $c->param('code'),
        "你需要提供上一个链接给你的 code",
    ) // return;

    $c->expect(
        $c->param('redirect_uri'),
        "你要提供重定向的链接地址",
    ) // return;

    my $auth_id = $c->expect(
        $c->db->get_auth_id_by_code($c->param('code')),
        "没有这个 code！你是不是在日我的网站",
    ) // return;

    say STDERR "auth_id is $auth_id";
    my $auth = $c->expect(
        $c->db->get_auth($auth_id),
        "数据库烂掉了",
    ) // return;

    $c->assert(
        $c->param('redirect_uri') eq $auth->{redirect_uri},
        "你这次提供的回调链接和上一次的不一样，为啥呢？",
    ) // return;

    # FIXME
    my $token_id = time;

    # FIXME: 这些玩意都是什么意思啊
    my $response  = $c->expect(
        $c->db->new_token(
            id => $token_id,
            uid => $auth->{uid},
            access_token => time,
            token_type => "bearer",
            expires_in => 0,
            refresh_token => time,
            scope => $auth->{scope},
        ),
        "新建 token 失败了，数据库烂掉了",
    ) // return;

    $c->expect(
        $c->db->drop_auth($auth_id),
        "没法删除认证请求，数据库烂掉了",
    ) // return;

    $c->ua->post(
        $auth->{redirect_uri},
        => json => $response
        => sub {}
    );

    $c->render(text => '');
};

app->start('daemon');
