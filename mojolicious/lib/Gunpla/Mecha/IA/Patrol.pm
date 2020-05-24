package Gunpla::Mecha::IA::Patrol;

use v5.10;
use Moo;
use Data::Dumper;

extends 'Gunpla::Mecha::IA';

has waypoints => (
    is => 'ro',
    default => sub { [ ] }
);

has aim => (
    is => 'rw'
);

sub elaborate
{
    my $self = shift;
    my $mecha = shift;
    my $world = shift;
    if($self->event_is($world, $mecha, undef))
    {
        $self->aim($self->my_wp);
        return { 
            command => 'flywp',
            params => $self->my_wp,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 6
        }
    }
    elsif($self->event_is($world, $mecha, 'exhausted energy'))
    {
        return { 
            command => 'flywp',
            params => $self->aim,
            secondarycommand => undef,
            secondaryparams => undef,
            velocity => 4
        }
    }
    elsif($self->event_is($world, $mecha, 'reached destination'))
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
    else
    {
        return undef;
    }
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


}
1;
