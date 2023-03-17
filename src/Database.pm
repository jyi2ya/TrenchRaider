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
    $json ||= q/{ "user": {}, "session": {},  "auth": {}, "token": {} }/;
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
    my ($auth_id, $code) = @p{qw/id code/};
    my $auths = $self->{_hash}->{auth};
    my $auth = $auths->{$auth_id};
    $auth->{code} = $code;
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

sub get_token_id_by_refresh_token {
    my ($self, $token) = @_;
    my $tokens = $self->{_hash}->{token};
    for (values %$tokens) {
        return $_->{id} if $_->{refresh_token} eq $token;
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

1;

