#!/usr/bin/env perl
use v5.12;
use utf8;
use warnings;
use open qw(:std :utf8);
use lib './';

use Mojolicious::Lite;
use Database;

my $database = Database->new();

get '/debug/kill/:uid' => sub {
};

# 用户的首页，好像没要求
# 哦，要求了。后面还要收藏番剧
get '/user/query/:uid' => sub {
    ...
};

# 登录
# TODO: 错误处理
get '/user/login' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $password = $c->param('password');
    my $user = $database->load_by_name($name);
    die unless defined $user;
    die unless defined $user->try_login($c->session, $password);
    $c->render(text => 'ok');
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
# FIXME: 错误处理
post '/user/new' => sub {
    my ($c) = @_;
    my $name = $c->param('name');
    my $password = $c->param('password');
    my $email = $c->param('email');
    my $nickname = $c->param('nickname');
    my $description = $c->param('description');

    my $user = User->from_hash({
            name => $name,
            password => $password,
            email => $email,
            nickname => $nickname,
            description => $description,
        });

    $database->store_user($user);
    $c->render(text => 'ok');
};

# 上传用户头像……怎么做
post '/user/upload_avantar' => sub {
    ...
};

# 删除用户
post '/user/drop' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $user = $database->load_by_name($name);
    die unless defined $user;
    die unless defined $user->is_login($c->session);
    ...
};

# 全量更新用户信息
put '/user/replace' => sub {
    ...
};

# 差量更新用户信息
patch '/user/update' => sub {
    ...
};

# oauth，首先在这里得到一个页面，同时验证用户正是本人……
get '/oauth/authorize' => sub {
    my ($c) = @_;
    my $response_type = $c->param('response_type');
    my $client_id = $c->param('client_id');
    my $redirect_uri = $c->param('redirect_uri');
    my $scope = $c->param('scope');
    my $state = $c->param('state');

    ...
};

# 然后用户点击神秘链接后再跳到这里，然后这里会调用第三方 app 提供的回调链接送出 code……
get '/oauth/confirm_authorize' => sub {
    ...
};

# 然后第三方 app 再用 code 在这里拿 token。
# 妈的，这个还要支持 refresh_token
get '/oauth/token' => sub {
    my ($c) = @_;
    my $client_id = $c->param('client_id');
    my $client_secret = $c->param('client_secret');
    my $grant_type = $c->param('grant_type');
    my $code = $c->param('code');
    my $redirect_uri = $c->param('redirect_uri');

    ...
};

app->start;
