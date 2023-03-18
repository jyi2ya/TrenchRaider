#!/usr/bin/env perl
use utf8;

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

    my $client = $c->expect(
        $c->db->get_client($c->param('client_id')),
        text => '这个客户端没注册过',
        status => 403,
    ) // return;

    my $auth_id = _uuid;

    $c->expect(
        $c->db->new_auth_request(
            id => $auth_id,
            uid => $uid,
            code => undef,
            expire => time + 600,

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
    my $client_owner = $c->expect(
        $c->db->get_user($client->{uid}),
        text => '这个客户端的主人已经似了',
        status => 500,
    ) // return;
    my $scope = $c->param('scope');
    $c->render(
        text => <<eof
来自 $client_owner->{name} 的 id 为 $client_id 的客户端想要你的 $scope 权限
如果你同意的话就访问这个：<a href="/auth/confirm_authorize?id=$auth_id">$auth_id</a>
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

    $c->assert(
        time() < $auth->{expire},
        text => '验证过期啦',
        status => 403,
    ) // return;

    my $code = _uuid;

    $c->expect(
        $c->db->set_auth_code(
            id => $auth_id,
            code => $code,
            expire => time + 600,
        ),
        text => "没法把 code 放到数据库里，坏掉了",
        status => 500,
    ) // return;

    my $uri = Mojo::URL->new($auth->{redirect_uri})
        ->query({
            code => $code,
            state => $auth->{state},
        });
    $c->redirect_to($uri);
};

helper give_token => sub {
    my ($c) = @_;

    $c->expect(
        $c->param('client_id'),
        status => 400,
        json => { error => 'invalid_request' },
    ) // return;

    my $client = $c->expect(
        $c->db->get_client($c->param('client_id')),
        status => 403,
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

    my $token_id = _uuid;

    my $oidc_token = undef;
    if (grep { $_ eq 'openid' } split ' ', $auth->{scope}) {
        $oidc_token = Mojo::JWT->new(
            claims => {
                iss => $c->root_uri,
                sub => $auth->{uid},
                aud => $auth->{client_id},
                exp => time + 3600,
                iat => time,
                auth_time => time,
            },

            secret => $client->{secret},
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

    my $new_access_token = _uuid;
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
            issuer => $c->root_uri,
            authorization_endpoint => $c->root_uri . "/auth/authorize",
            token_endpoint => $c->root_uri . "/auth/token",
            userinfo_endpoint => $c->root_uri . "/auth/userinfo",
        }
    );
};
