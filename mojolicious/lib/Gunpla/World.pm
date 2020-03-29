package Gunpla::World;

use Moo;
use MongoDB;
use Gunpla::Position;
use Gunpla::Mecha;

has name => (
    is => 'ro',
);

has waypoints => (
    is => 'ro',
    default => sub { {} }
);

has armies => (
    is => 'ro',
    default => sub { [] }
);

has spawn_points => (
    is => 'ro',
    default => sub { {} }
);





sub add_mecha
{
    my $self = shift;
    my $name = shift;
    my $faction = shift;
    #TODO: check if mecha already exists
    my $mecha = Gunpla::Mecha->new(name => $name, faction => $faction);
    $mecha->position($self->waypoints->{$self->spawn_points->{$faction}}->clone());
    $mecha->destination($mecha->position->clone());
    push @{$self->armies}, $mecha;
}

sub get_mecha_by_name
{
    my $self = shift;
    my $name = shift;
    foreach my $m (@{$self->armies})
    {
        return $m if($m->name eq $name);
    }
    return undef;
}


sub init
{
    my $self = shift;
    print "Init...\n";
    $self->waypoints->{'center'} = Gunpla::Position->new(x => 0, y => 0, z => 0);
    $self->waypoints->{'blue'} = Gunpla::Position->new(x => 500000, y => 0, z => 0);
    $self->waypoints->{'red'} = Gunpla::Position->new(x => -500000, y => 0, z => 0);
    $self->spawn_points->{'wolf'} = 'blue';
    $self->spawn_points->{'eagle'} = 'red';
    $self->add_mecha("Diver", "wolf");
    $self->add_mecha("Zaku", "eagle");
}

sub add_command
{
    my $self = shift;
    my $mecha = shift;
    my $command = shift;
    my $params = shift;
    my $m = $self->get_mecha_by_name($mecha);
    if($command eq 'FLY TO WAYPOINT')
    {
        $m->command($command . " " . $params);
        $m->destination($self->waypoints->{$params}->clone());
        $m->waiting(0);
    }
}



sub all_ready
{
    my $self = shift;
    for(@{$self->armies})
    {
        return 0 if $_->waiting;
    }
    return 1;
}


sub action
{
    my $self = shift;
    my $steps = shift;
    my $counter = 0;
    while($self->all_ready &&
          (! $steps || $counter < $steps))
    {
        for(@{$self->armies})
        {
            my $m = $_;
            if(! $m->destination->equals($m->position))
            {
                $m->plan_and_move();
            }
            else
            {
                $m->waiting(1);
                $self->event($m->name . " reached destination");
            }
        }
        $counter++;
    }
    if($steps && $counter >= $steps)
    {
        $self->event("All steps executed");
    }
}

sub event
{
    my $self = shift;
    my $message = shift;
    say $message;
}

sub is_spawn_point
{
    my $self = shift;
    my $name = shift;
    for(keys %{$self->spawn_points})
    {
        if($self->spawn_points->{$_} eq $name)
        {
            return $_;
        }
    }
    return 0;
}


sub save
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    $db->drop();
    foreach my $m (@{$self->armies})
    {
        $db->get_collection('mecha')->insert_one($m->to_mongo);
        foreach my $wp (keys %{$self->waypoints})
        {
            my $wp_mongo = {
                name => $wp,
                type => 'waypoint',
                position => $self->waypoints->{$wp}->to_mongo(),
                spawn_point => $self->is_spawn_point($wp)
            };
            $db->get_collection('map')->insert_one($wp_mongo);
        }
    }
}

sub load
{
    my $self = shift;
    my $mongo = MongoDB->connect();
    my $db = $mongo->get_database('gunpla_' . $self->name);
    my @mecha = $db->get_collection('nations')->find()->all();
    for(@mecha)
    {
        push @{$self->armied}, Gunpla::Mecha->from_mongo($_);
    }
    my @map_points = $db->get_collection('map')->find()->all();
    foreach my $mapp (@map_points)
    {
        if($mapp->{type} eq 'waypoint')
        {
            $self->waypoints->{$mapp->{name}} = Gunpla::Position->from_mongo($mapp->{position});
            if($mapp->{spawn_point})
            {
                $self->spawn_points->{$mapp->{spawn_point}} = $mapp->{name};
            }
        }
    }

}

1;

