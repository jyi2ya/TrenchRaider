package User;
use Storable;

sub new {
    my $class = shift;
    my $self = {
        _hash => undef,
    };
    bless $self, $class;

    $self
}

sub from_hash {
    my ($class, $hash) = @_;
    my $self = {
        _hash => $hash
    };
    bless $self, $class;

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
    my ($self, $token) = @_;
    $self->{_hash}->{login_token} eq $token;
}

sub try_login {
    my ($self, $password) = @_;
    if ($self->password eq $password) {
        # FIXME: 生成真正的 token
        $self->{_hash}->{login_token} = int rand(100000);
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

sub to_hash {
    my ($self) = @_;
    Storable::dclone($self->{_hash})
}

1;