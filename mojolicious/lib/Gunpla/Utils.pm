package Gunpla::Utils;

use base 'Exporter';
our @EXPORT_OK = qw( controlled target_from_mongo_to_json mecha_from_mongo_to_json sighted_by_me sighted_by_faction command_from_mongo_to_json);

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
    delete $command->{_id};
    my $callback = '/game/targets?' . join('&', "game=$game", "mecha=$mecha", "filter=$filter");
    $command->{params_callback} = $callback;
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
    my $type;
    if($source eq 'mechas')
    {
        $type = 'mecha';
    }
    elsif($source eq 'map')
    {
        $type = $obj->{type}
    }
    my $label = $type . " " . $id . " " . $obj_pos->as_string;
    $label .= " d:$distance" if($distance);
    my $world_id = ELEMENT_TAGS->{$type} . '-' . $id;

    return { id => $id,
             world_id => $world_id,
             label => $label,
             map_type => $type,
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
             max_velocity => $mecha->{max_velocity},
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
