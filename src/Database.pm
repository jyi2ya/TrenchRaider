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

sub load_by_name {
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

