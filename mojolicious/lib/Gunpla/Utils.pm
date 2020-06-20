package Gunpla::Utils;

use base 'Exporter';
our @EXPORT_OK = qw( controlled target_from_mongo_to_json mecha_from_mongo_to_json sighted_by_me sighted_by_faction command_from_mongo_to_json get_from_id get_game_events);

use Data::Dumper;
use MongoDB;
use Gunpla::Position;
use Gunpla::Constants ':all';

sub controlled
{
    my $game = shift;
    my $mecha = shift;
    my $user = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $controlled ) = $db->get_collection('control')->find({ player => $user, mecha => $mecha })->all();
    return $controlled ? 1 : 0;
}

sub command_from_mongo_to_json
{
    my $command = shift;
    my $mecha = shift;
    my $game = shift;
    my $filter = $command->{filter};
    my $min_distance = $command->{min_distance};
    my $max_distance = $command->{max_distance};
    delete $command->{_id};
    if($filter)
    {
        my $callback = '/game/targets?' . join('&', "game=$game", "mecha=$mecha", "filter=$filter");
        $callback .= "&min-distance=$min_distance" if defined $min_distance;
        $callback .= "&max-distance=$max_distance" if defined $max_distance;
        $command->{params_callback} = $callback;
    }
    else
    {
        $command->{params_callback} = undef
    }
    return $command;
}


sub target_from_mongo_to_json
{
    my $game = shift;
    my $mecha = shift;
    my $source = shift;
    my $obj = shift;

    my $distance = undef;
    my $obj_pos = Gunpla::Position->from_mongo($obj->{position});
    if($mecha)
    {
        my $mecha_pos_mongo = undef;
        my $client = MongoDB->connect();
        my $db = $client->get_database('gunpla_' . $game);
        my ( $mecha_obj ) = $db->get_collection('mechas')->find({ name => $mecha })->all();
        if($mecha_obj)
        {
            $mecha_pos_mongo = $mecha_obj->{position} if $mecha_obj;
            my $mecha_pos = Gunpla::Position->from_mongo($mecha_pos_mongo);
            $distance = $mecha_pos->distance($obj_pos);
        }
    }

    my $id = exists $obj->{name} ? $obj->{name} : $obj->{id};
    my $world_id;
    my $tag;
    if($source eq 'mechas')
    {
        $tag = 'MEC';
        $world_id = $tag . '-' . $id;
    }
    elsif($source eq 'map')
    {
        $tag = $obj->{type};
        $world_id = $tag . '-' . $id;
    }
    elsif($source eq 'position')
    {
        $world_id = $obj_pos->as_string(1);
        $tag = 'POS';
    }
    my $label = $obj->{label} ? $obj->{label} : ELEMENT_TAGS->{$tag} . " " . $id;
    $label .= " " . $obj_pos->as_string;
    $label .= " d:$distance" if($distance);

    return { id => $id,
             world_id => $world_id,
             label => $label,
             map_type => $tag,
             x    => $obj->{position}->{x},
             y    => $obj->{position}->{y},
             z    => $obj->{position}->{z},
             distance => $distance,
    }
}

sub mecha_from_mongo_to_json
{
    my $mecha = shift;
    return { name     => $mecha->{name},
             label     => $mecha->{name},
             map_type => 'mecha',
             world_id => 'MEC-' . $mecha->{name},   
             life     => $mecha->{life},
             faction  => $mecha->{faction},
             position => $mecha->{position},
             velocity => $mecha->{velocity},
             energy   => $mecha->{energy},
             max_velocity => $mecha->{max_velocity},
             available_max_velocity => $mecha->{available_max_velocity},
             waiting  => $mecha->{waiting} };
}

sub sighted_by_me
{
    my $game = shift;
    my $mecha = shift;
    my $obj = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $sighting_matrix ) = $db->get_collection('status')->find({ status_element => 'sighting_matrix' })->all();
    return $sighting_matrix->{$mecha}->{$obj->{name}} > 0;
}
sub sighted_by_faction
{
    my $game = shift;
    my $mecha = shift;
    my $obj = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha_obj ) = $db->get_collection('mechas')->find({ name => $mecha })->all();
    my ( $sighting_matrix ) = $db->get_collection('status')->find({ status_element => 'sighting_matrix' })->all();
    return $sighting_matrix->{__factions}->{$mecha_obj->{faction}}->{$obj->{name}} > 0;
}

sub get_from_id
{
    my $game = shift;
    my $world_id = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ($type, $id) = split('-', $world_id);
    my $obj = undef;
    my $source = undef;
    if($type eq 'MEC')
    {
        ( $obj ) = $db->get_collection('mechas')->find({ name => $id })->all();
        $source = 'mechas';
    }
    else
    {
        ( $obj ) = $db->get_collection('map')->find({ type => $type, id => $id })->all();
        $source = 'map';
    }
    $obj->{source} = $source;
    return $obj;
}

sub get_game_events
{
    my $game = shift;
    my $mecha = shift;
    my $cmd_index = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('gunpla_' . $game);
    my @out = ();
    if($mecha)
    {
        my ( $mecha_obj ) = $db->get_collection('mechas')->find({ name => $mecha })->all();
        $cmd_index = $mecha_obj->{cmd_index} if ! $cmd_index;
        my @events = $db->get_collection('events')->find({ mecha => $mecha, cmd_index => $cmd_index, blocking => 1})->all();
        for(@events)
        {
            push @out, $_->{message};
        } 
    }
    else
    {
        my @all = $db->get_collection('mechas')->find()->all();
        foreach my $mecha_obj (@all)
        {
            $cmd_index = $mecha_obj->{cmd_index} if ! $cmd_index;
            my @events = $db->get_collection('events')->find({ mecha => $mecha_obj->{name}, cmd_index => $cmd_index, blocking => 1})->all();
            for(@events)
            {
                push @out, $_->{message},
            } 
        }
    }
    return \@out;
}

