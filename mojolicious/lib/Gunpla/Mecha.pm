package Gunpla::Mecha;

use v5.10;
use Moo;
use Gunpla::Constants ':all';
use Gunpla::Position;
use Data::Dumper;


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
has inertia => (
    is => 'rw',
    default => 0
);
has suspended_command => (
    is => 'rw',
);

#Navigation
has movement_target => (
    is => 'rw',
    default => sub { { } },
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
#Advanced navigation
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
has velocity_target => (
    is => 'rw',
    default => 0,
);
#Combat
has attack => (
    is => 'rw'
);
has attack_target => (
    is => 'rw',
    default => sub { { type => 'none' } }
);
has attack_limit => (
    is => 'rw',
);
has attack_gauge => (
    is => 'rw',
);
#Action
has action => (
    is => 'rw'
);
has action_gauge => (
    is => 'rw',
);


#Characteristics
has life => (
    is => 'rw'
);
has energy => (
    is => 'rw'
);
has max_energy => (
    is => 'ro'
);
has sensor_range => (
    is => 'ro',
);
has status => (
    is => 'rw',
    default => sub { [] }
);
has log_file => (
    is => 'rw',
);

with 'Gunpla::Mecha::Role::IA';

sub is_status
{
    my $self = shift;
    my $status = shift;
    if(grep { $_ eq $status } @{$self->status})
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


sub add_status
{
    my $self = shift;
    my $status = shift;
    if(! $self->is_status($status))
    {
        push @{$self->status}, $status;
    }
}

sub delete_status
{
    my $self = shift;
    my $status  = shift;
    my @new = grep { $_ ne $status} @{$self->status};
    if($status eq 'landed')
    {
        $self->delete_status('sensor-array-linked') if $self->is_status('sensor-array-linked');
    }
    $self->status(\@new);
}

sub mod_attack_gauge
{
    my $self = shift;
    my $value = shift;
    my $new_value = $self->attack_gauge + $value;
    $new_value = $new_value < 0 ? 0 : $new_value;
    $self->attack_gauge($new_value);
}

sub mod_action_gauge
{
    my $self = shift;
    my $value = shift;
    my $new_value = $self->action_gauge + $value;
    $new_value = $new_value < 0 ? 0 : $new_value;
    $self->action_gauge($new_value);
}

sub mod_inertia
{
    my $self = shift;
    my $value = shift;
    my $new_value = $self->inertia + $value;
    $new_value = $new_value < 0 ? 0 : $new_value;
    $self->inertia($new_value);
}


sub stop_landing
{
    my $self = shift;
    $self->stop_action() if ($self->action && $self->action eq 'LANDING');
}

sub stop_action
{
    my $self = shift;
    $self->action(undef);
}

sub stop_movement
{
    my $self = shift;
    $self->movement_target({});
    $self->course->{steps} = 0;
    $self->course->{direction} = 0;
    $self->course->{axis} = '';
    $self->destination($self->position);
    $self->velocity(0);
    $self->acceleration_gauge(0);
    $self->velocity_gauge(0);
    $self->velocity_vector(undef);
    $self->velocity_target(0);
}

sub stop_attack
{
    my $self = shift;
    $self->attack(undef);
    $self->attack_target({ type => 'none' });
    $self->attack_limit(0);
    $self->attack_gauge(0);
}

sub get_velocity
{
    my $self = shift;
    if($self->attack && $self->attack eq 'SWORD')
    {
        return SWORD_VELOCITY;
    } 
    elsif($self->action && $self->action eq 'BOOST')
    {
        return BOOST_VELOCITY;
    }
    else
    {
        $self->velocity();
    }
}
sub acceleration_needed
{
    my $self = shift;
    if($self->attack && $self->attack eq 'SWORD')
    {
        return 0;
    } 
    else
    {
        return($self->velocity < $self->velocity_target);
    }
}

sub ok_velocity
{
    my $self = shift;
    my $move = 0;
    if($self->get_velocity > 0)
    {
        $self->velocity_gauge($self->velocity_gauge + 1);
        if($self->velocity_gauge > (VELOCITY_LIMIT  - $self->get_velocity))
        {
            $self->velocity_gauge(0);
            $move = 1;
        }
    }
    if($self->acceleration_needed())
    {
        $self->acceleration_gauge($self->acceleration_gauge + 1);
        if($self->acceleration_gauge > $self->acceleration)
        {
            $self->velocity($self->velocity + 1);
            $self->acceleration_gauge(0);
        }
    }
    elsif($self->velocity > $self->velocity_target)
    {
        $self->velocity($self->velocity_target);
    }
    return $move;
}

sub set_destination
{
    my $self = shift;
    my $destination = shift;
    $self->destination($destination);
    $self->course->{steps} = 0; #Reset previous course
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
                else
                {
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
            $self->delete_status('landed') if $self->is_status('landed');
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

sub set_drift
{
    my $self = shift;
    my $rand = shift;
    my @dirs = qw (x y z);
    my $direction = $dirs[$rand];
    return if($self->get_velocity() == 0);
    return if($self->velocity_vector->$direction == 0);
    my $course = { axis => $direction,
                   direction => $self->velocity_vector->$direction > 0 ? 1 : -1,
                   steps => 1 };
    $self->course($course);
}

sub drift_and_move
{
    my $self = shift;
    my $rand = shift;
    if(! $self->move())
    {
        $self->set_drift($rand);
        $self->move();
    }
}



sub energy_routine
{
    my $self = shift;
    my $energy_delta = ENERGY_STANDARD_BONUS;

    if($self->attack && $self->attack eq 'SWORD')
    {
        $energy_delta -= ENERGY_SWORD_VELOCITY_MALUS;
    } 
    elsif($self->action && $self->action eq 'BOOST')
    {
        $energy_delta -= ENERGY_BOOST_MALUS;
    }
    else
    {
        my $high_velocity = $self->max_velocity - 1;
        if($self->get_velocity == $self->max_velocity)
        {
            $energy_delta -= ENERGY_MAX_VELOCITY_MALUS;
        }
        elsif($self->get_velocity == $high_velocity)
        {
            $energy_delta -= ENERGY_HIGH_VELOCITY_MALUS;
        }
    }
    $self->add_energy($energy_delta);
}
sub add_energy
{
    my $self = shift;
    my $energy = shift;
    my $new = $self->energy + $energy;
    $new = 0 if($new < 0);
    $new = $self->max_energy if($new > $self->max_energy);
    $self->energy($new);
    $self->energy_exhausted if($self->energy == 0);
}
sub energy_exhausted
{
    my $self = shift;
    if($self->velocity > $self->max_velocity - 2)
    {
        $self->velocity($self->max_velocity - 2);
        $self->velocity_target($self->max_velocity - 2);
    }
}


sub command
{
    my $self = shift;
    my $command = shift;
    my $target = shift;
    my $velocity = shift;
    $velocity = $self->velocity_target if(! $velocity);
    if($command eq 'flywp')
    {
        $self->stop_attack();    
        $self->stop_action();    
        $self->set_destination($target->{position}->clone());
        $self->movement_target({ type => 'WP', 'name' => $target->{name}, class => 'fixed'  });
        $self->velocity_target($velocity);
    }
    elsif($command eq 'flyhot')
    {
        $self->stop_attack();    
        $self->stop_action();    
        $self->set_destination($target->{position}->clone());
        $self->movement_target({ type => $target->{type}, 'name' => $target->{id}, class => 'fixed', nearby => 1  });
        $self->velocity_target($velocity);
    }
    elsif($command eq 'flymec')
    {
        $self->stop_attack();    
        $self->stop_action();    
        $self->set_destination($target->position->clone());
        $self->movement_target({ type => 'MEC', 'name' => $target->name, class => 'dynamic', nearby => 1  });
        $self->velocity_target($velocity);
    }
    elsif($command eq 'sword')
    {
        if($self->attack && $self->attack eq 'SWORD' && $self->attack_limit > 0 && $self->attack_target->{name} eq $target->name)
        {
            #Resume. We do nothing, leaving sword going on
        }
        else
        {
            my $actual_velocity = $self->get_velocity();
            $self->stop_movement();
            $self->stop_attack();    
            $self->attack('SWORD');
            $self->set_destination($target->position->clone());
            $self->movement_target({ type => 'MEC', 'name' => $target->name, class => 'dynamic'  });
            $self->attack_target({ type => 'MEC', 'name' => $target->name, class => 'dynamic'  });
            $self->attack_limit(SWORD_ATTACK_TIME_LIMIT);
            $self->log("Attack gauge start is " . SWORD_GAUGE_VELOCITY_BONUS . " * " . $actual_velocity);
            $self->attack_gauge(SWORD_GAUGE_VELOCITY_BONUS * $actual_velocity);
            $self->stop_action(); #Here to transmit BOOST to GAUGE_VELOCITY_BONUS
        }
    }
    elsif($command eq 'away')
    {
        my $position;
        if(ref $target eq 'HASH')
        {
            $position = $target->{position};
        }
        else
        {
            $position = $target->position;
        }
        $self->stop_action();    
        $self->stop_attack();    
        my $destination = $self->position->away_from($position, GET_AWAY_DISTANCE);
        $self->set_destination($destination);
        $self->movement_target({ type => 'VOID', name => 'space', class => 'fixed'  });
        $self->velocity_target($velocity);
    }
    elsif($command eq 'wait')
    {
        $self->stop_movement();
        $self->stop_attack();    
        $self->stop_action();    
    }
    elsif($command eq 'rifle')
    {
        if($self->attack && $self->attack eq 'RIFLE' && $self->attack_limit > 0 && $self->attack_target->{name} eq $target->name)
        {
            #Resume. We do nothing, leaving rifle going on
        }
        else
        {
            $self->stop_action();    
            $self->stop_attack();    
            $self->stop_movement();
            $self->attack_limit(RIFLE_ATTACK_TIME_LIMIT);
            $self->attack('RIFLE');
            $self->attack_target({ type => 'MEC', 'name' => $target->name, class => 'dynamic'  });
            $self->attack_gauge(0);
        }
    }
    elsif($command eq 'land')
    {
        $self->stop_attack();    
        $self->stop_action();    
        $self->action("LAND");
        $self->set_destination($target->{position}->clone());
        $self->velocity_target(LANDING_VELOCITY);
        $self->movement_target({ type => $target->{type}, 'name' => $target->{id}, class => 'fixed' });
        
    }
    elsif($command eq 'machinegun')
    {
        if($self->attack && $self->attack eq 'MACHINEGUN' && $self->attack_limit > 0 && $self->attack_target->{name} eq $target->name)
        {
            #Resume. We do nothing, leaving machinegun order to exhaust the shots
        }
        else
        {
            $self->stop_attack();    
            $self->attack_limit(MACHINEGUN_SHOTS);
            $self->attack('MACHINEGUN');
            $self->attack_target({ type => 'MEC', 'name' => $target->name, class => 'dynamic'  });
            $self->attack_gauge(0);
        }
    }
    elsif($command eq 'boost')
    {
        $self->stop_attack();    
        $self->stop_action();    
        $self->action("BOOST");
        $self->action_gauge(BOOST_GAUGE);
    }
    elsif($command eq 'last')
    {
        #The target arriving here is the actual position of the mecha. We want the last position when on sight
        my $true_target;
        my $true_destination;
        if((! $self->movement_target || ! $self->movement_target->{type} eq 'none') && $self->attack_target && $self->attack_target->{type} eq 'mecha') 
        {
            $true_target =  $self->attack_target;
        }
        elsif($self->movement_target && $self->movement_target->{type} eq 'mecha') 
        {
            $true_target =  $self->movement_target
        }
        $true_destination = $self->destination;
        $self->stop_attack();    
        $self->stop_action();    
        $self->set_destination($true_destination->clone());
        $self->movement_target({ type => 'LMEC', 'name' => $target->{name}, class => 'fixed'  });
        $self->velocity_target($velocity);
    }
    elsif($command eq 'guard')
    {
        $self->stop_movement();
        $self->stop_attack();    
        $self->stop_action();    
        $self->action("GUARD");
        $self->action_gauge($target);
    }
    else
    {
        die "Unrecognized command $command";    
    }
    $self->delete_status('stuck');
}



sub to_mongo
{
    my $self = shift;
    return {
        name => $self->name,
        faction => $self->faction,
        waiting => $self->waiting,
        position => $self->position ? $self->position->to_mongo() : undef,
        course => $self->course,
        movement_target => $self->movement_target,
        destination => $self->destination ? $self->destination->to_mongo() : undef,
        velocity => $self->velocity,
        acceleration => $self->acceleration,
        acceleration_gauge => $self->acceleration_gauge,
        max_velocity => $self->max_velocity,
        velocity_gauge => $self->velocity_gauge,
        velocity_vector => $self->velocity_vector ? $self->velocity_vector->to_mongo() : undef,
        velocity_target => $self->velocity_target,
        cmd_index => $self->cmd_index,
        cmd_fetched => $self->cmd_fetched,
        inertia => $self->inertia,
        suspended_command => $self->suspended_command,
        sensor_range => $self->sensor_range,
        life => $self->life,
        attack => $self->attack,
        attack_target => $self->attack_target,
        attack_limit => $self->attack_limit,
        attack_gauge => $self->attack_gauge,
        life => $self->life,
        status => $self->status,
        action => $self->action,
        action_gauge => $self->action_gauge,
        energy => $self->energy,
        max_energy => $self->max_energy,
        log_file => $self->log_file,
        IA => $self->ia_to_mongo(),
    }
}

sub from_mongo
{
    my $package = shift;
    my $data = shift;
    my $position = $data->{position};
    my $destination = $data->{destination};
    my $velocity_vector = $data->{velocity_vector};
    my $IA = $data->{IA};
    delete $data->{position};
    delete $data->{destination};
    delete $data->{velocity_vector};
    my $m = $package->new($data);
    $m->position(Gunpla::Position->from_mongo($position));
    $m->destination(Gunpla::Position->from_mongo($destination));
    $m->velocity_vector(Gunpla::Position->from_mongo($velocity_vector));
    if($IA)
    {
        $m->ia_from_mongo($IA);
    }
    return $m;  
}

sub log
{
    my $self = shift;
    return if ! $self->log_file;
    my $message = shift;
    $message = "[M:" . $self->name . "] ". $message;
    open(my $fh, '>> ' . $self->log_file);
    print {$fh} $message . "\n";
    close($fh);
}

sub relevant_target
{
    my $self = shift;
    my $type = shift;
    my $name = shift;
    if(($self->movement_target && $self->movement_target->{type} && $self->movement_target->{type} eq $type &&  $self->movement_target->{name} && $self->movement_target->{name} eq $name) ||
       ($self->attack_target   && $self->attack_target->{type}   && $self->attack_target->{type}   eq $type && $self->attack_target->{name}    && $self->attack_target->{name}   eq $name))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


1;
