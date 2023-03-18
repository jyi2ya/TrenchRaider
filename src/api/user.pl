#!/usr/bin/env perl
use utf8;

helper logined_user_id => sub {
    my $c = shift;
    my $session_id = $c->session->{session_id};
    $c->db->get_uid_by_session($session_id);
};

helper send_email_to_user => sub {
    my ($c, $uid) = @_;

    my $email_id = _uuid;

    my $user = $c->expect(
        $c->db->get_user($uid),
        text => '用户不存在',
        status => 400,
    ) // return;

    my $root_uri = $c->root_uri;

    $c->assert(
        system(
            qw/swaks --to/, $user->{email}, qw/--body/,
            qq{听我说，你要点这个链接然后验证你的身份 $root_uri/api/user/verify_email?id=$email_id}
        ) eq 0,
        text => '没法发送邮件，太坏了',
        status => 500,
    ) // return undef;

    $c->expect(
        $c->db->new_email(
            id => $email_id,
            uid => $uid,
        ),
        text => "新建邮件出问题了",
        status => 500,
    ) // return undef;

    1;
};

# 邮箱验证
get '/api/user/verify_email' => sub {
    my $c = shift;

    my $id = $c->expect(
        $c->param('id'),
        text => '怎么没有邮件id，你是不是在日我站',
        status => 400,
    ) // return;

    my $uid = $c->expect(
        $c->db->get_uid_by_email_id($id),
        text => '没有这个邮件',
        status => 404,
    ) // return;

    $c->expect(
        $c->db->set_verified($uid),
        text => '没法把这个用户设置成验证通过的',
        status => 500,
    ) // return;

    $c->render(text => '好耶，现在你可以随便使用这个网站的服务了！');
};



# 登录
post '/api/user/login' => sub {
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
        $user->{is_verified},
        text => '有这个用户，但是还没有验证邮件',
        status => 403,
    ) // return;

    $c->assert(
        $password eq $user->{password},
        text => "密码不对",
        status => 403,
    ) // return;

    my $session_id = _uuid;

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
get '/api/user/verify_email' => sub {
    my $c = shift;

    my $id = $c->expect(
        $c->param('id'),
        text => '怎么没有邮件id，你是不是在日我站',
        status => 400,
    ) // return;

    my $uid = $c->expect(
        $c->db->get_uid_by_email_id($id),
        text => '没有这个邮件',
        status => 404,
    ) // return;

    $c->expect(
        $c->db->set_verified($uid),
        text => '没法把这个用户设置成验证通过的',
        status => 500,
    ) // return;

    $c->render(text => '好耶，现在你可以随便使用这个网站的服务了！');
};

get '/api/user/resend_email' => sub {
    my $c = shift;

    my $uid = $c->expect(
        $c->param('id'),
        text => '你要给我 uid',
        status => 400,
    ) // return;

    my $user = $c->expect(
        $c->db->get_user($uid),
        text => '用户不存在',
        status => 404
    ) // return;

    $c->assert(
        time() > $user->{cooldown},
        text => '给你发的邮件太多了，建议你等会再来',
        status => 400,
    ) // return;

    $c->send_email_to_user($uid) // return;
    $c->db->set_user_cooldown($uid, time + 60);

    $c->render(text =>
        qq{
        <html><body><p>
        好力。如果你没收到邮件，就点这里重新要一份 <a href="/api/user/resend_email?id=$uid">点这里</a>
        </p></body></html>
        }
    );
};

# 新建用户
post '/api/user/new' => sub {
    my ($c) = @_;

    my $uid = _uuid;

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
        $c->param('box'),
        text => "你要提供邮箱",
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
            email => $c->param('box'),
            nickname => $c->param('nickname'),
            profile =>  $c->param('profile'),
            is_verified => undef,
            cooldown => time + 60,
        ),
        text => "新建用户失败了",
        status => 500,
    ) // return;

    $c->send_email_to_user($uid) // return;
    $c->db->set_user_cooldown($uid, time + 60);

    $c->render(text =>
        qq{好力。如果你没收到邮件，就点这里重新要一份 <a href="/api/user/resend_email?id=$uid">点这里</a>}
    );
};

# 删除用户
post '/api/user/drop' => sub {
    my $c = shift;

    my $uid = $c->expect(
        $c->logined_user_id,
        text => "好像还没登录",
        status => 403,
    ) // return;

    $c->db->drop_user($uid);

    $c->render(text => '已杀掉');
};

# 全量更新用户信息
put '/api/user/replace' => sub {
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
            profile =>  $c->param('profile'),
        ),
        text => "没法更新，数据库好像坏掉了",
        status => 500,
    ) // return;

    $c->render(text => "好力\n");
};

# 差量更新用户信息
patch '/api/user/update' => sub {
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
            profile =>  $c->param('profile'),
        ),
        text => "没法更新，数据库好像坏掉了",
        status => 500,
    ) // return;

    $c->render(text => "好力\n");
};


# 上传用户头像……怎么做
post '/api/user/upload_avantar' => sub {
    ...
};
