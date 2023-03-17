package Database;
# FIXME: 呃呃数据库

use Storable;
use JSON;

sub new {
    my $class = shift;
    local $/ = undef;
    system qw/touch db.json/;
    open my $in, '<', 'db.json';
    binmode $in;
    my $json = <$in>;
    $json ||= q/{ "user": {}, "email": {}, "session": {},  "auth": {}, "token": {} }/;
    my $db = decode_json $json;
    my $self = {
        _hash => $db,
    };
    bless $self, $class;

    $self->sync;

    $self
}

sub sync {
    my $self = shift;
    open my $fd, '>', 'db.json';
    binmode $fd;
    print $fd encode_json($self->{_hash});
    close $fd;
}

sub get_uid_by_session {
    my ($self, $session_id) = @_;
    my $sessions = $self->{_hash}->{session};
    $sessions->{$session_id}->{uid}
}

sub get_uid_by_name {
    my ($self, $name) = @_;
    my $users = $self->{_hash}->{user};
    for (values %$users) {
        return $_->{id} if $_->{name} eq $name;
    }
    undef;
}

sub get_user {
    my ($self, $uid) = @_;
    my $users = $self->{_hash}->{user};
    $users->{$uid}
}

sub has_user_name {
    my ($self, $name) = @_;
    if (defined $self->get_uid_by_name($name)) {
        1
    } else {
        0
    }
}

sub new_user {
    my ($self, @p) = @_;
    my $users = $self->{_hash}->{user};
    my $user = { @p };
    $users->{$user->{id}} = $user;
    $self->sync;
}

sub replace_user {
    my ($self, %p) = @_;
    ...
}

sub update_user {
    my ($self, %p) = @_;
    ...
}

sub new_auth_request {
    my ($self, @p) = @_;
    my $auths = $self->{_hash}->{auth};
    my $auth = { @p };
    $auths->{$auth->{id}} = $auth;
    $self->sync;
}

sub set_auth_code {
    my ($self, %p) = @_;
    my ($auth_id, $code, $expire) = @p{qw/id code expire/};
    my $auths = $self->{_hash}->{auth};
    my $auth = $auths->{$auth_id};
    $auth->{code} = $code;
    $auth->{expire} = $expire;
    $self->sync;
}

sub get_auth {
    my ($self, $auth_id) = @_;
    my $auths = $self->{_hash}->{auth};
    my $auth = $auths->{$auth_id};
    $auth;
}

sub get_auth_id_by_code {
    my ($self, $code) = @_;
    my $auths = $self->{_hash}->{auth};
    for (values %$auths) {
        return $_->{id} if $_->{code} eq $code;
    }
    undef;
}

sub new_token {
    my ($self, @p) = @_;
    my $tokens = $self->{_hash}->{token};
    my $token = { @p };
    $tokens->{$token->{id}} = $token;
    $self->sync;
}

sub get_token {
    my ($self, $id) = @_;
    my $tokens = $self->{_hash}->{token};
    $tokens->{$id}
}

sub get_token_response {
    my ($self, $id) = @_;
    my $tokens = $self->{_hash}->{token};
    my $token = $tokens->{$id};

    my $response = {
        map { $_ => $token->{$_} }
        qw/access_token token_type expires_in refresh_token scope/
    };

    $response->{id_token} = $token->{id_token} if defined $token->{id_token};

    $response
}

sub get_token_id_by_refresh_token {
    my ($self, $token) = @_;
    my $tokens = $self->{_hash}->{token};
    for (values %$tokens) {
        return $_->{id} if $_->{refresh_token} eq $token;
    }
    undef;
}

sub get_token_id_by_access_token {
    my ($self, $token) = @_;
    my $tokens = $self->{_hash}->{token};
    for (values %$tokens) {
        return $_->{id} if $_->{access_token} eq $token;
    }
    undef;
}

sub set_access_token {
    my ($self, $token_id, $access) = @_;
    my $tokens = $self->{_hash}->{token};
    my $token = $tokens->{$token_id};
    $token->{access_token} = $access;
    $self->sync;
}

sub set_verified {
    my ($self, $uid) = @_;
    my $users = $self->{_hash}->{user};
    my $user = $users->{$uid};
    $user->{is_verified} = 1;
    $self->sync;
}

sub set_user_cooldown {
    my ($self, $uid, $cooldown) = @_;
    my $users = $self->{_hash}->{user};
    my $user = $users->{$uid};
    $user->{cooldown} = $cooldown;
    $self->sync;
}

sub drop_user {
    my ($self, $uid) = @_;
    my $users = $self->{_hash}->{user};
    delete $users->{$uid};
    $self->sync;
}

sub drop_auth {
    my ($self, $auth_id) = @_;
    my $auths = $self->{_hash}->{auth};
    delete $auths->{$auth_id};
    $self->sync;
}

sub new_session {
    my ($self, @p) = @_;
    my $sessions = $self->{_hash}->{session};
    my $session = { @p };
    $sessions->{$session->{id}} = $session;
    $self->sync;
}

sub get_uid_by_email_id {
    my ($self, $id) = @_;
    my $emails = $self->{_hash}->{email};
    my $email = $emails->{$id};
    $email->{uid};
}

sub new_email {
    my ($self, @p) = @_;
    my $emails = $self->{_hash}->{email};
    my $email = { @p };
    $emails->{$email->{id}} = $email;
    $self->sync;
}

sub new_client {
    my ($self, @p) = @_;
    my $clients = $self->{_hash}->{client};
    my $client = { @p };
    $clients->{$client->{id}} = $client;
    $self->sync;
}

sub get_client {
    my ($self, $id) = @_;
    my $clients = $self->{_hash}->{client};
    $clients->{$id}
}

1;

