package Gunpla::Mechadrome;
use v5.10;
use Moo;

extends 'Gunpla::World';

use constant MECHA_NEARBY => 1000;

has counter => (
    is => 'rw',
    default => 0
);

has report => (
    is => 'rw',
    default => undef
);
has full_record => (
    is => 'rw',
    default => 0
);


sub init_drome
{
    my $self = shift;
    say "Init...\n";
    $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
    $self->waypoints->{'blue'} = Gunpla::Position->new(x => 200000, y => 0, z => 0);
    $self->waypoints->{'red'} = Gunpla::Position->new(x => -500000, y => 0, z => 0);
    $self->waypoints->{'alpha'} = Gunpla::Position->new(x => 0, y => -200000, z => 0);
    $self->waypoints->{'ulysses'} = Gunpla::Position->new(x => -300000, y => 0, z => 0);
    $self->waypoints->{'eracles'} = Gunpla::Position->new(x => -200000, y => 0, z => 0);
    $self->spawn_points->{'wolf'} = 'blue';
    $self->add_mecha("Diver", "wolf");
}

sub race
{
    my $self = shift;
    my $waypoints = shift;
    my $velocity = shift;
    my $steps = shift;
    if($self->report)
    {
        open(my $rfh, ">> " . $self->report);
        print {$rfh} "=====\n";
        print {$rfh} "Max velocity: " . $self->armies->[0]->max_velocity . "\n";    
        print {$rfh} "Acceleration: " . $self->armies->[0]->acceleration . "\n";
        print {$rfh} "Track: WP-blue -> " . join(" -> ", @{$waypoints}) . "\n";
        print {$rfh} "\n";
        close($rfh);
    }


    foreach my $wp (@{$waypoints})
    {
        $self->armies->[0]->waiting(0);
        $self->add_command('Diver', { command => 'FLY TO WAYPOINT', params => $wp, velocity => $velocity });
        while($self->all_ready && (! $steps || $self->counter < $steps))
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
                $m->energy_routine();
                my $scan = "Step: " . $self->counter . "\n" .
                           "Waypoint: $wp" . "\n" .
                           "Mecha position: " . $m->position->as_string() . "\n" .
                           "Velocity: " . $m->velocity . "\n" .
                           "Velocity Gauge: " . $m->velocity_gauge . "\n" .
                           "Acceleration Gauge: " . $m->velocity_gauge . "\n" .
                           "Velocity vector: " . $m->velocity_vector->as_string() . "\n" .
                           "Energy: " . $m->energy;

                if($self->counter % 1000 == 0)
                {
                    say $scan;
                }
                if($self->full_record && $self->report)
                {    open(my $rfh, ">> " . $self->report);
                     print {$rfh} "$scan\n\n";
                     close($rfh);
                }
            }
            $self->counter($self->counter+1);
            
        }
    }
    if($self->report)
    {
        open(my $rfh, ">> " . $self->report);
        print {$rfh} "\n\n";
        close($rfh);
    }
}

sub event
{
    my $self = shift;
    my $message = shift;
    my $involved = shift;
    say $self->counter . ": " . $message;
    if($self->report)
    {
        open(my $rfh, ">> " . $self->report);
        print {$rfh} $self->counter. ": " . $message. "\n";
        close($rfh);
    }
    for(@{$involved})
    {
        my $m = $self->get_mecha_by_name($_);
        $m->waiting(1);
        $m->cmd_fetched(0);
        $self->generated_events($self->generated_events + 1);
    }
}

1;
