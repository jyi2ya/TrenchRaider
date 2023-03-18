#!/usr/bin/env perl
use v5.12;
use utf8;
use warnings;
use open qw(:std :utf8);

post '/api/client/new' => sub {
    my $c = shift;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    my $secret = $c->expect(
        $c->param('secret'),
        text => '你要给一个 secret，要不然没法加密！',
        status => 400,
    ) // return;

    my $id = _uuid;

    $c->expect(
        $c->db->new_client(
            id => $id,
            uid => $uid,
            secret => $secret,
        ),
        text => '数据库似喽',
        status => 500,
    ) // return;

    $c->render(
        json => {
            client_id => $id,
        }
    );
};

