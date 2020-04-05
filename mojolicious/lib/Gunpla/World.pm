package Gunpla::World;

use v5.10;
use Moo;
use MongoDB;
use Gunpla::Position;
use Gunpla::Mecha;

use constant SIGHT_TOLERANCE => 10000;

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
has sighting_matrix => (
    is => 'ro',
    default => sub { {} }
);
has generated_events => (
    is => 'rw',
    default => 0
);



#Dummy implementation of mecha characteristics
has mecha_templates => (
    is => 'ro',
    default => sub {
        {
            'Diver' => { sensor_range => 140000 },
            'Zaku'  => { sensor_range => 80000 }
        }
    }
);





sub add_mecha
{
    my $self = shift;
    my $name = shift;
    my $faction = shift;
    #TODO: check if mecha already exists
    my $template = $self->mecha_templates->{$name};
    $template->{name} = $name;
    $template->{faction} = $faction;
    my $mecha = Gunpla::Mecha->new($template);
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
    $self->waypoints->{'alpha'} = Gunpla::Position->new(x => 0, y => -200000, z => 0);
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
        $m->destination($self->waypoints->{$params}->clone());
    }
    $m->cmd_fetched(1);
}

sub fetch_commands_from_mongo
{
    my $self = shift;
    for(@{$self->armies})
    {
        my $m = $_;
        if((! $m->waiting) && (! $m->cmd_fetched))
        {
            my $mongo = MongoDB->connect();
            my $db = $mongo->get_database('gunpla_' . $self->name);
            my ( $command ) = $db->get_collection('commands')->find({ mecha => $m->name, cmd_index => $m->cmd_index })->all();
            $self->add_command($m->name, $command->{command}, $command->{params});
        }
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

sub all_ready_and_fetched
{
    my $self = shift;
    for(@{$self->armies})
    {
        return 0 if ($_->waiting || (! $_->cmd_fetched));
    }
    return 1;
}


sub action
{
    my $self = shift;
    my $steps = shift;
    my $counter = 0;
    my $events = 0;
    $self->generated_events(0);
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
                $events++;
                $self->event($m->name . " reached destination", [ $m->name ]);
            }
            $self->calculate_sighting_matrix($m->name);
        }
        $counter++;
    }
    $self->cmd_index_up();
    if($steps && $counter >= $steps)
    {
        $events++;
        $self->event("All steps executed", []);
    }
    return $self->generated_events();
}

sub cmd_index_up
{
    my $self = shift;
    foreach my $m(@{$self->armies})
    {
        if($m->waiting)
        {
            $m->cmd_index($m->cmd_index+1);
        }
    }
}

sub event
{
    my $self = shift;
    my $message = shift;
    my $involved = shift;

    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $self->name);
    for(@{$involved})
    {
        my $m = $self->get_mecha_by_name($_);
        say "Adding event for " . $m->name; 
        #$m->cmd_index($m->cmd_index + 1);
        my $cmd_index = $m->cmd_index + 1;
        $db->get_collection('events')->insert_one({ message   => $message,
                                                    mecha     => $m->name,
                                                    cmd_index => $cmd_index });
        $m->waiting(1);
        $m->cmd_fetched(0);
    }
    $self->generated_events($self->generated_events + 1);
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
    $db->get_collection('mechas')->drop();
    $db->get_collection('map')->drop();
    foreach my $m (@{$self->armies})
    {
        $db->get_collection('mechas')->insert_one($m->to_mongo);
    }
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

sub load
{
    my $self = shift;
    my $mongo = MongoDB->connect();
    my $db = $mongo->get_database('gunpla_' . $self->name);
    my @mecha = $db->get_collection('mechas')->find()->all();
    for(@mecha)
    {
        push @{$self->armies}, Gunpla::Mecha->from_mongo($_);
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

sub calculate_sighting_matrix
{
    my $self = shift;
    my $mecha_name = shift;
    my $m = $self->get_mecha_by_name($mecha_name);
    foreach my $other (@{$self->armies})      
    {
        if($m->faction ne $other->faction) #Mechas of the same faction are always visible each other 
        {
            if(! exists $self->sighting_matrix->{$m->name}->{$other->name})
            {
                $self->sighting_matrix->{$m->name}->{$other->name} = 0;
            }
            if($m->position->distance($other->position) < $m->sensor_range)
            {
                if($self->sighting_matrix->{$m->name}->{$other->name} == 0)
                {
                    $self->sighting_matrix->{$m->name}->{$other->name} = SIGHT_TOLERANCE;
                    $self->event($m->name . " sighted " . $other->name, [ $m->name ]);
                }
            }
            else
            {
                if($self->sighting_matrix->{$m->name}->{$other->name} > 0)
                {
                    $self->sighting_matrix->{$m->name}->{$other->name} -= 1;
                    if($self->sighting_matrix->{$m->name}->{$other->name} == 0)
                    {
                        $self->event($m->name . " lost contact with  " . $other->name, [ $m->name ]);
                    }
                }
            }
        }
    }
}


1;

