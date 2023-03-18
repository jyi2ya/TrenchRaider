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

# FIXME: 这太坏了……
sub _hash {
    my $text = shift;
    `echo \Q$text\E | md5sum`
}

# FIXME: 这太坏了……
sub _uuid {
    `cat /proc/sys/kernel/random/uuid | tr -d '[[:space:]]'`
}

helper root_uri => sub {
    "http://172.27.114.79:3000"
};

helper db => (
    sub {
        my $db = Database->new();
        sub { $db };
    }
)->();

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

helper form => sub {
    my $c = shift;
    my %items = @_;
    my $endpoint = delete $items{endpoint};
    my $method = delete $items{method};

    my $page = qq{
<!DOCTYPE html>
<html lang="en">
<head>
    <div>
        <table style="margin: 0px auto; text-align: center;">};
    $page .= qq{<form name="form1" method="$method" action="$endpoint">};
    for (sort keys %items) {
        $page .= qq{
            <tr>
                <td>$items{$_}:</td>
                <td><input type="text" name="$_" placeholder="$items{$_}"></td>
            </tr>
        };
    }
    $page .= qq{
            <tr>
                <td></td>
                <td><input type="submit" value="Submit"></td>
            </tr>
            </tbody>
            </form>
        </table>
    </div>
</head>
};
    $c->render(text => $page);

    for (sort keys %items) {
    }
};

get '/lwiw' => sub {
    my $c = shift;
    $c->redirect_to('https://store.steampowered.com/app/1594940');
};

get '/debug/kill/:uid' => sub {
};

# 用户的首页，好像没要求
# 哦，要求了。后面还要收藏番剧
get '/user/query/:uid' => sub {
    ...
};

get '/user/login' => sub {
    my $c = shift;
    $c->form(
        endpoint => '/api/user/login',
        method => 'post',
        name => '用户名',
        password => '密码',
    );
};

get '/user/register' => sub {
    my $c = shift;
    $c->form(
        endpoint => '/api/user/new',
        method => 'post',
        name => '用户名',
        nickname => '昵称',
        password => '密码',
        box => '邮箱',
        profile => '简介',
    );
};

get '/client/register' => sub {
    my $c = shift;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    $c->form(
        endpoint => '/api/client/new',
        method => 'post',
        secret => '用来加密 id token 的神秘字符串',
    );
};

# 从 bangumi 偷数据
get '/steal_data_from_bangumi' => sub {
    ...
};

# 各种回调函数，不过估计只有 bangumi 小偷会用到
post '/callback/:type/:id' => sub {
    ...
};

do 'api/user.pl';
do 'api/auth.pl';
do 'api/client.pl';

app->start;
