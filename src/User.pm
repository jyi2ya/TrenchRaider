package User;
use Storable;

# FIXME: 写一个真正的哈希函数
sub _hash {
    my $text = shift;
    length $text;
}

sub new {
    my $class = shift;
    my $self = {
        _hash => undef,
    };
    bless $self, $class;

    $self
}

sub from_raw_hash {
    my ($class, $hash) = @_;
    my $self = {
        _hash => $hash
    };
    bless $self, $class;

    $self
}

sub from_hash {
    my $self = from_raw_hash @_;
    $self->password(_hash($self->password));
    $self
}

sub _get_or_set {
    my ($self, $key, $val) = @_;
    if (defined $val) {
        $self->{_hash}->{$key} = $val;
    }
    $self->{_hash}->{$key};
}

sub is_login {
    my ($self, $session) = @_;
    $self->{_hash}->{login_token} eq $session->{login_token};
}

sub try_login {
    my ($self, $session, $password) = @_;
    $password = _hash($password);
    if ($self->password eq $password) {
        # FIXME: 生成真正的 token
        my $login_token = int rand(100000);
        $self->{_hash}->{login_token} = $login_token;
        $session->{login_token} = $login_token;
        1;
    } else {
        undef
    }
}

sub name { _get_or_set $_[0], 'name', $_[1] }
sub email { _get_or_set $_[0], 'email', $_[1] }
sub description { _get_or_set $_[0], 'description', $_[1] }
sub nickname { _get_or_set $_[0], 'nickname', $_[1] }
sub password { _get_or_set $_[0], 'password', $_[1] }
sub login_token { _get_or_set $_[0], 'login_token', $_[1] }
sub auth_requests { _get_or_set $_[0], 'auth_requests', $_[1] }

sub to_hash {
    my ($self) = @_;
    Storable::dclone($self->{_hash})
}

sub as_hash {
    my ($self) = @_;
    $self->{_hash}
}

sub new_authorize_request {
    my ($self, $auth) = @_;

    # FIXME: 真正的 unique id
    $auth->{id} = time;
    $self->{_hash}->{auth_requests}->{$auth->{id}} = $auth;
    $auth->{id};
}

sub confirm_authorize {
    my ($self, $auth_id) = @_;

    die unless defined $self->{_hash}->{auth_requests}->{$auth_id};
    my $auth = $self->{_hash}->{auth_requests}->{$auth_id};

    # FIXME: 真正的 code
    $auth->{code} = time;

    $auth;
}

sub borrow_auth_by_code {
    my ($self, $code) = @_;

    for my $auth (values %{$self->auth_requests}) {
        if ($auth->{code} eq $code) {
            return $auth;
        }
    }

    undef;
}

sub finish_authorize {
    my ($self, $auth) = @_;
    $self->{_hash}->{finished_auths} //= {};
    my $finished = $self->{_hash}->{finished_auths};

    # FIXME: 这些玩意都是什么意思啊
    $finished->{$auth->{id}} = {
        "access_token" => time,
        "token_type" => "bearer",
        "expires_in" => 0,
        "refresh_token" => time,
        "scope" => "",
        "uid" => 0,
    };

    delete $self->{_hash}->{auth_requests}->{$auth->{id}};
    $finished->{$auth->{id}};
}

1;
