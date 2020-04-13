package Gunpla::Mechadrome;
use v5.10;
use Moo;

extends 'Gunpla::World';

use constant MECHA_NEARBY => 1000;

sub init_drome
{
    my $self = shift;
    say "Init...\n";
    $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
    $self->waypoints->{'blue'} = Gunpla::Position->new(x => 500000, y => 0, z => 0);
    $self->waypoints->{'red'} = Gunpla::Position->new(x => -500000, y => 0, z => 0);
    $self->waypoints->{'alpha'} = Gunpla::Position->new(x => 0, y => -200000, z => 0);
    $self->spawn_points->{'wolf'} = 'blue';
    $self->add_mecha("Diver", "wolf");
}

sub race
{
    my $self = shift;
    my $waypoints = shift;
    my $steps = shift;
    my $counter = 0;
    foreach my $wp (@{$waypoints})
    {
        $self->armies->[0]->waiting(0);
        $self->add_command('Diver', 'FLY TO WAYPOINT', $wp);
        while($self->all_ready && (! $steps || $counter < $steps))
        {
            for(@{$self->armies})
            {
                my $m = $_;
                if($m->movement_target)
                {
                    if($m->movement_target->{type} eq 'mecha')
                    {
                        my $target = $self->get_mecha_by_name($m->movement_target->{name});
                        $m->set_destination($target->position->clone);
                        if($m->position->distance($target->position) > MECHA_NEARBY)
                        {
                            $m->plan_and_move();
                        }
                        else
                        {
                            $self->event($m->name . " reached the nearby of " . $m->movement_target->{type} . " " . $m->movement_target->{name}, [ $m->name ]);
                        }
                    }
                    else
                    {
                        if(! $m->destination->equals($m->position))
                        {
                            $m->plan_and_move();
                        }
                        else
                        {
                            $self->event($m->name . " reached destination: " . $m->movement_target->{type} . " " . $m->movement_target->{name}, [ $m->name ]);
                        }
                    }
                }
                if($m->velocity == $m->max_velocity)
                {
                    die "Max velocity reached at $counter";
                }
                if($counter % 1000 == 0)
                {
                    say "Step: $counter";
                    say "Waypoint: $wp";
                    say "Mecha position: " . $m->position->as_string();
                    say "Velocity: " . $m->velocity;
                    say "Velocity Gauge: " . $m->velocity_gauge;
                    say "Acceleration Gauge: " . $m->velocity_gauge;
                    say "Velocity vector: " . $m->velocity_vector->as_string();
                }
            }
            $counter++;
            
        }
    }
}

sub event
{
    my $self = shift;
    my $message = shift;
    my $involved = shift;
    say $message;

    for(@{$involved})
    {
        my $m = $self->get_mecha_by_name($_);
        $m->waiting(1);
        $m->cmd_fetched(0);
        $self->generated_events($self->generated_events + 1);
    }
}

1;
