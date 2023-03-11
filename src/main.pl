#!/usr/bin/env perl
use v5.12;
use utf8;
use warnings;
use open qw(:std :utf8);

use Mojolicious::Lite;

# 用户的首页，好像没要求
# 哦，要求了。后面还要收藏番剧
get '/user/:uid' => sub {
    ...
};

# 登录
get '/user/login' => sub {
    ...
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
    ...
};

# 删除用户
post '/user/drop' => sub {
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
