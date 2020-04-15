package Gunpla::Mecha;

use v5.10;
use Moo;
use Gunpla::Position;
use Data::Dumper;

use constant VELOCITY_LIMIT => 11;

#Identity
has name => (
    is => 'ro'
);
has faction => (
    is => 'ro'
);

#Command management
has waiting => (
    is => 'rw',
    default => 1
);
has cmd_fetched => (
    is => 'rw',
    default => 0
);
has cmd_index => (
    is => 'rw',
    default => 0
);

#Navigation
has movement_target => (
    is => 'rw',
    default => sub { { } }
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
#Advanced navigatio
has velocity => (
    is => 'rw',
    default => 0
);
has acceleration => (
    is => 'rw',
);
has acceleration_gauge => (
    is => 'rw',
    default => 0
);
has acceleration_matrix => (
    is => 'ro',
    default => sub { 
        {
            '1.5' => undef,
            '1' => 4,
            '0.5' => 3,
            '-1' => 2
        }
    }
);
has max_velocity => (
    is => 'rw',
    default => 5
);
has velocity_gauge => (
    is => 'rw',
    default => 0
);
has velocity_vector => (
    is => 'rw',
);

#Combat
has attack => (
    is => 'rw'
);
has attack_target => (
    is => 'rw',
    default => sub { { } }
);
has attack_limit => (
    is => 'rw',
);
has gauge => (
    is => 'rw',
);
has life => (
    is => 'rw'
);


#Characteristics
has sensor_range => (
    is => 'ro',
);

sub ok_velocity
{
    my $self = shift;
    my $move = 0;
    if($self->velocity > 0)
    {
        $self->velocity_gauge($self->velocity_gauge + 1);
        if($self->velocity_gauge > (VELOCITY_LIMIT  - $self->velocity))
        {
            $self->velocity_gauge(0);
            $move = 1;
        }
    }
    if($self->velocity < $self->max_velocity)
    {
        $self->acceleration_gauge($self->acceleration_gauge + 1);
        if($self->acceleration_gauge > $self->acceleration)
        {
            $self->velocity($self->velocity + 1);
            $self->acceleration_gauge(0);
        }
    }
    return $move;
}

sub set_destination
{
    my $self = shift;
    my $destination = shift;
    $self->destination($destination);
    my $destination_vector = $self->position->vector($destination, 1, 1);
    if($self->velocity_vector)
    {
        my $stir = $destination_vector->sum($self->velocity_vector);
        for(sort { $b <=> $a } keys %{$self->acceleration_matrix})
        {
            my $l = $_;
            if($stir > $l)
            {
                if($self->acceleration_matrix->{$l})
                {
                    $self->velocity($self->acceleration_matrix->{$l}) if $self->velocity > $self->acceleration_matrix->{$l};
                    last;
                }
            }
        }
    }
    $self->velocity_vector($destination_vector);
}



sub move
{
    my $self = shift;
    if($self->course->{steps} > 0)
    {
        if($self->ok_velocity)
        {
            my $ax = $self->course->{axis};
            $self->position->$ax($self->position->$ax + $self->course->{direction});
            $self->course->{steps} = $self->course->{steps} - 1;
            return 1;
        }
        else
        {
            return -1;
        }
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
    if($self->movement_target->{class} eq 'dynamic')
    {
        #Allow the mech to adjust the course more frequently in case of movable target
        $self->course->{steps} = 10 if $self->course->{steps} > 10;
    }
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
        movement_target => $self->movement_target,
        destination => $self->destination->to_mongo(),
        velocity => $self->velocity,
        acceleration => $self->acceleration,
        acceleration_gauge => $self->acceleration_gauge,
        max_velocity => $self->max_velocity,
        velocity_gauge => $self->velocity_gauge,
        velocity_vector => $self->velocity_vector->to_mongo(),
        cmd_index => $self->cmd_index,
        cmd_fetched => $self->cmd_fetched,
        sensor_range => $self->sensor_range,
        life => $self->life,
        attack => $self->attack,
        attack_target => $self->attack_target,
        attack_limit => $self->attack_limit,
        gauge => $self->gauge,
        life => $self->life
    }
}

sub from_mongo
{
    my $package = shift;
    my $data = shift;
    my $position = $data->{position};
    my $destination = $data->{destination};
    my $velocity_vector = $data->{velocity_vector};
    delete $data->{position};
    delete $data->{destination};
    delete $data->{velocity_vector};
    my $m = $package->new($data);
    $m->position(Gunpla::Position->from_mongo($position));
    $m->destination(Gunpla::Position->from_mongo($destination));
    $m->velocity_vector(Gunpla::Position->from_mongo($velocity_vector));
    return $m;  
}





1;
