package Gunpla::Mecha::IA::Patrol;

use v5.10;
use Moo;
use Gunpla::Utils qw(sighted_by_faction target_from_mongo_to_json);
use Data::Dumper;

extends 'Gunpla::Mecha::IA';

### PATROL
#
# Mecha fly between a set of waypoints. When an enemy is on sight it attacks. If two mechas are already on target the target is ignored



has waypoints => (
    is => 'ro',
    default => sub { [ ] }
);

has aim => (
    is => 'rw'
);

has last_command => (
    is => 'rw'
);

sub already_on_target
{
    my $self = shift;
    my $target = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $self->game);
    my @mec = $db->get_collection('mechas')->find({ faction => $self->faction})->all();
    my $counter = 0;
    for(@mec)
    {
        $counter++ if($_->{name} ne $self->mecha && $_->{life} > 0 && $_->{IA}->{aim} && $_->{IA}->{aim} eq $target);
    }
    return $counter;
}

sub manage_targets
{
    my $self = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $self->game);
    my @mec = $db->get_collection('mechas')->find()->all();
    my @targets;
    for(@mec)
    {
        if(sighted_by_faction($self->game, $self->mecha, $_))
        {
            my $m = target_from_mongo_to_json($self->game, $self->mecha, 'mechas', $_);
            push @targets, $m;
        }
    }
    if(@targets)
    {
        foreach my $t (@targets)
        {
            my $already = $self->already_on_target($t->{world_id});
            if($already < 2)
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
                        velocity => 4
                    }
                }
            }
        }
    }
    return undef;
}


sub manage_events
{
    my $self = shift;
    if($self->event_is(undef))
    {
        $self->aim($self->my_wp);
        return { 
            command => 'flywp',
            params => $self->my_wp,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }
    elsif($self->event_is('exhausted energy'))
    {
        return { 
            command => 'flywp',
            params => $self->aim,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }
    elsif($self->event_is('reached destination'))
    {
        my $target = $self->next_wp;
        $self->aim($target);
        return { 
            command => 'flywp',
            params => $target,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }
    elsif($self->event_is('contact lost'))
    {
        return {
            command => 'last',
            params => $self->aim,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }
    else
    {
        my $target = $self->next_wp;
        $self->aim($target);
        return { 
            command => 'flywp',
            params => $target,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }

}


sub elaborate
{
    my $self = shift;
    my $target_managed = $self->manage_targets();
    my $out;
    if($target_managed)
    {
        $out = $target_managed;
    }
    else
    {
        $out = $self->manage_events();
    }
    $self->last_command($out);
    return $out;
}


sub my_wp
{
    my $self = shift;
    my $nwp = @{$self->waypoints};
    my $wp_index = $self->mecha_index % $nwp;
    return $self->waypoints->[$wp_index];
}

sub next_wp
{
    my $self = shift;
    for(my $i = 0; $i < @{$self->waypoints}; $i++)
    {
        if($self->waypoints->[$i] eq $self->aim)
        {
            my $index = $i +1;
            if($index == @{$self->waypoints})
            {
                return $self->waypoints->[0];
            }
            else
            {
                return $self->waypoints->[$index];
            }
        }
    }
    return $self->waypoints->[0];
}

sub to_mongo
{
    my $self = shift;
    return { 
        package => __PACKAGE__,
        mecha_index => $self->mecha_index,
        mecha => $self->mecha,
        faction => $self->faction,
        game => $self->game,
        waypoints => $self->waypoints,
        aim => $self->aim,
        last_command => $self->last_command,
    };
}
1;
