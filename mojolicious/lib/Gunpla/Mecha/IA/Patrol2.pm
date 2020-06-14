package Gunpla::Mecha::IA::Patrol2;

use v5.10;
use Moo;
use Gunpla::Utils qw(sighted_by_faction target_from_mongo_to_json);
use Data::Dumper;

extends 'Gunpla::Mecha::IA::Patrol';

### PATROL
#
# Mecha fly between a set of waypoints. When an enemy is on sight it attacks. If two mechas are already on target the target is ignored. 
# If no mecha is on target it asks for support

sub manage_targets
{
    my $self = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $self->game);

    my @mec = $db->get_collection('mechas')->find()->all();
    my @targets;
    my $on_wait = 0;
    my $to_call = undef;
    my $min_distance = 1000000000000000000000;
    foreach my $am (@mec)
    {
        if(sighted_by_faction($self->game, $self->mecha, $am))
        {
            my $m = target_from_mongo_to_json($self->game, $self->mecha, 'mechas', $am);
            push @targets, $m;
        }
        if($am->{faction} eq $self->faction && $am->{name} ne $self->mecha)
        {
            if($am->{waiting})
            {
                $on_wait++;
                say STDERR $self->mecha .  ": Putting on wait for " . $am->{name};
            }
            else
            {
                my $f = target_from_mongo_to_json($self->game, $self->mecha, 'mechas', $am);
                if($f->{distance} < $min_distance)
                {
                    $to_call = $f->{world_id};
                    say STDERR $self->mecha .  ": Friend to call is " . $f->{world_id};
                }
            }
        }
    }
    if(@targets)
    {
        foreach my $t (@targets)
        {
            my $already = $self->already_on_target($t->{world_id});
            say STDERR $self->mecha .  ": already is $already, on_wait is $on_wait";
            if($already == 0 && ! $on_wait)
            {
                $self->aim($t->{world_id});
                return {
                    command => 'support',
                    params => $to_call
                }
            }
            elsif($already < 2)
            {
                $self->aim($t->{world_id});
                if($t->{distance} < 2000)
                {
                    return { 
                        command => 'sword',
                        params => $t->{world_id},
                        secondarycommand => undef,
                        secondaryparams => undef,
                        velocity => undef
                    }
                }
                else
                {
                    return { 
                        command => 'flymec',
                        params => $t->{world_id},
                        secondarycommand => 'machinegun',
                        secondaryparams => $t->{world_id},
                        velocity => 6
                    }
                }
            }
        }
    }
    return undef;
}

1;

