package Gunpla::Sight;

use v5.10;
use Moo;
use Gunpla::Constants ":all";
use Data::Dumper;

has matrix => (
    is => 'rw',
    default => sub { {} },
);

has factions => (
    is => 'rw',
    default => sub { {} }
);

sub init
{
    my $self = shift;
    my $armies = shift;
    foreach my $m (@{$armies})
    {
        foreach my $other (@{$armies})      
        {
            if($m->faction ne $other->faction)
            {
                $self->matrix->{$m->name}->{$other->name} = 0;
                $self->factions->{$m->faction}->{$other->name} = 0;
            }
        }
    }
}

sub reset
{
    my $self = shift;
    my $armies = shift;
    $self->init($armies);
    $self->calculate(undef, $armies);

}

sub mod_faction
{
    my $self = shift;
    my $faction = shift;
    my $target = shift;
    my $mod = shift;
    $self->factions->{$faction}->{$target} = $self->factions->{$faction}->{$target} + $mod;
    if($self->factions->{$faction}->{$target} < 0)
    {
        say STDERR "$faction-$target sighting matrix below 0";
        $self->factions->{$faction}->{$target} = 0;
    }
}

sub turn_on_mecha2mecha
{
    my $self = shift;
    my $from = shift;
    my $target = shift;
    $self->matrix->{$from}->{$target} = SIGHT_TOLERANCE;
}


sub decrease_mecha2mecha
{
    my $self = shift;
    my $from = shift;
    my $target = shift;
    return 0 if  $self->matrix->{$from}->{$target} == 0;
    $self->matrix->{$from}->{$target} =  $self->matrix->{$from}->{$target} - 1;
    $self->matrix->{$from}->{$target} = 0 if  $self->matrix->{$from}->{$target} < 0;
    return $self->matrix->{$from}->{$target} == 0;
}



sub calculate
{
    my $self = shift;
    my $target = shift;
    my $armies = shift;
    my @do = ();
    my @out_events = ();
    if($target)
    {
        @do = grep { $_->name eq $target} @{$armies};
    }
    else
    {
        @do = @{$armies};
    }
    foreach my $m (@do)
    {
        foreach my $other (@{$armies})      
        {
            if($m->faction ne $other->faction) #Mechas of the same faction are always visible each other 
            {
                my $threshold = $m->sensor_range;
                if($threshold > 0) #Blind mechas remain blind
                {
                    $threshold += SIGHT_SENSOR_ARRAY_BONUS if $m->is_status('sensor-array-linked');
                    $threshold -= SIGHT_LANDED_BONUS if $other->is_status('landed');
                    $threshold = SIGHT_MINIMUM if $threshold < SIGHT_MINIMUM;
                }
                if($m->position->distance($other->position) < $threshold)
                {
                    if($self->matrix->{$m->name}->{$other->name} == 0)
                    {
                        if($self->factions->{$other->faction}->{$m->name})
                        {
                            $m->mod_inertia(INERTIA_SECOND_SIGHT);
                        }
                        push @out_events, [ $m->name, $other->name, 1];
                        $self->mod_faction($m->faction, $other->name, 1);
                    }
                    $self->turn_on_mecha2mecha($m->name, $other->name);
                }
                else
                {
                    if($self->decrease_mecha2mecha($m->name, $other->name))
                    {
                        $self->mod_faction($m->faction, $other->name, -1);
                        push @out_events, [ $m->name, $other->name, -1];
                    }
                }
            }
        }
    }
    return @out_events;
}

sub remove_from_matrix
{
    my $self = shift;
    my $mecha = shift;
    my $armies = shift;
    my @out_events = ();
    foreach my $t (@{$armies})
    {
        if($mecha->faction ne $t->faction)
        {
            if($self->matrix->{$mecha->name}->{$t->name} > 0)
            {
                $self->matrix->{$mecha->name}->{$t->name} = 0;
                $self->mod_faction($mecha->faction, $t->name, -1);
            }
            $self->matrix->{$t->name}->{$mecha->name} = 0;
        }
    }
    foreach my $f (keys %{$self->factions})
    {
        if($f ne $mecha->faction)
        {
            $self->factions->{$f}->{$mecha->name} = 0;
        }    
    }
    return @out_events;
}

sub see
{
    my $self = shift;
    my $from = shift;
    my $to = shift;
    return $self->matrix->{$from}->{$to} > 0;
}
sub see_faction
{
    my $self = shift;
    my $faction = shift;
    my $to = shift;
    return $self->factions->{$faction}->{$to} > 0;
}

sub load
{
    my $self = shift;
    my $sight_mongo = shift;
    $self->factions($sight_mongo->{__factions});
    delete $sight_mongo->{__factions};
    $self->matrix($sight_mongo);
}

sub to_mongo
{
    my $self = shift;
    my $out = { %{$self->matrix} };
    $out->{__factions} = { %{$self->factions} };
    return $out;
}

sub to_string
{
    my $self = shift;
    my $out = "MECHAS:\n";
    foreach my $see (keys %{$self->matrix})
    {
        $out .= "    $see -> [";
        my @i_see = grep { $self->matrix->{$see}->{$_} > 0 } keys %{$self->matrix->{$see}};
        $out .= join(",", @i_see) . "]\n";
    }
       $out .= "FACTIONS:\n";
    foreach my $see (keys %{$self->factions})
    {
        $out .= "    $see -> [";
        my @i_see = grep { $self->factions->{$see}->{$_} > 0 } keys %{$self->factions->{$see}};
        $out .= join(",", @i_see) . "]\n";
    }
    return $out;
}


1;
