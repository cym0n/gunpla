package Gunpla::Mecha;

use Moo;
use Gunpla::Position;

has name => (
    is => 'ro'
);
has faction => (
    is => 'ro'
);
has waiting => (
    is => 'rw',
    default => 1
);
has cmd_index => (
    is => 'rw',
    default => 0
);
has position => (
    is => 'rw',
);
has course => (
    is => 'rw',
    default => sub { { direction => 0, axis => '', steps => 0 } }
);
has destination => (
    is => 'rw',
);

sub move
{
    my $self = shift;
    if($self->course->{steps} > 0)
    {
        my $ax = $self->course->{axis};
        $self->position->$ax($self->position->$ax + $self->course->{direction});
        $self->course->{steps} = $self->course->{steps} - 1;
        return 1;
    }
    else
    {
        return 0;
    }
}

sub set_course
{
    my $self = shift;
    $self->course($self->position->course($self->destination));
}

sub plan_and_move
{
    my $self = shift;
    if(! $self->move())
    {
        $self->set_course();
        $self->move();
    }
}

sub to_mongo
{
    my $self = shift;
    return {
        name => $self->name,
        faction => $self->faction,
        waiting => $self->waiting,
        position => $self->position->to_mongo(),
        course => $self->course,
        destination => $self->destination->to_mongo(),
        cmd_index => $self->cmd_index,
    }
}

sub from_mongo
{
    my $package = shift;
    my $data = shift;
    my $position = $data->{position};
    my $destination = $data->{destination};
    delete $data->{position};
    delete $data->{destination};
    my $m = $package->new($data);
    $m->position(Gunpla::Position->from_mongo($position));
    $m->destination(Gunpla::Position->from_mongo($destination));
    return $m;  
}





1;
