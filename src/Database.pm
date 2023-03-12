package Database;
# FIXME: 呃呃数据库

use Storable;
use User;
use JSON;

sub new {
    my $class = shift;
    local $/ = undef;
    system qw/touch db.json/;
    open my $in, '<', 'db.json';
    binmode $in;
    my $json = <$in>;
    $json ||= '{}';
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

# FIXME: 遍历哈希表，非常差性能
sub borrow_logined_user {
    my ($self, $session) = @_;
    for my $name (keys %{$self->{_hash}}) {
        my $user = $self->borrow_user_by_name($name);
        return $user if $user->is_login($session);
    }
    undef;
}

# FIXME: 遍历哈希表，非常差性能
sub load_logined_user {
    my ($self, $session) = @_;
    my $user = $self->bowrrow_logined_user($session);
    if (defined $user) {
        Storable::dclone($user)
    } else {
        undef
    }
}

sub borrow_user_by_name {
    my ($self, $name) = @_;
    if (exists $self->{_hash}->{$name}) {
        User->from_hash($self->{_hash}->{$name})
    } else {
        undef
    }
}

sub load_user_by_name {
    my ($self, $name) = @_;
    if (exists $self->{_hash}->{$name}) {
        User->from_hash(Storable::dclone($self->{_hash}->{$name}))
    } else {
        undef
    }
}

sub store_user {
    my ($self, $user) = @_;
    $self->{_hash}->{$user->name} = $user->to_hash;
    $self->sync;
}

sub drop_user_by_name {
    my ($self, $name) = @_;
    delete $self->{_hash}->{$name};
}

sub contains_by_name {
    my ($self, $name) = @_;
    exists $self->{_hash}->{$name};
}

1;

