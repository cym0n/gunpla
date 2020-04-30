package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use lib "../../";

use MongoDB;
use Gunpla::Constants ':all';
use Gunpla::Position;
use Data::Dumper;


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

sub waypoint_from_mongo_to_json
{
    my $wp = shift;
    return { name     => $wp->{name},
             label     => $wp->{name},
             map_type => 'waypoint',
             world_id => 'WP-' . $wp->{name},   
             x    => $wp->{position}->{x},
             y    => $wp->{position}->{y},
             z    => $wp->{position}->{z} }
}

sub hotspot_from_mongo_to_json
{
    my $hot = shift;
    my $mecha = shift;
    return waypoint_from_mongo_to_json($hot) if $hot->{type} eq 'waypoint';
    my $hot_pos = Gunpla::Position->from_mongo($hot->{position});
    my $mecha_pos = Gunpla::Position->from_mongo($mecha->{position});
    my $distance = $mecha_pos->distance($hot_pos);
    my %tags = ( 'asteroid' => 'AST' );


    return { id => $hot->{id},
             label => $hot->{type} . " " . $hot_pos->as_string . " d:$distance",
             map_type => $hot->{type},
             world_id => $tags{$hot->{type}} . '-' . $hot->{id},
             x    => $hot->{position}->{x},
             y    => $hot->{position}->{y},
             z    => $hot->{position}->{z},
             distance => $distance,
    }
}
sub command_from_mongo_to_json
{
    my $command = shift;
    my $mecha_name = shift;
    my $game = shift;
    delete $command->{_id};
    my $callback = $command->{params_callback};
    $callback =~ s/%%GAME%%/$game/;
    $callback =~ s/%%MECHA%%/$mecha_name/;
    $command->{params_callback} = $callback;
    return $command;
}

sub owned
{
    my $mecha = shift;
    my $ownership = shift;
    return grep {$_->{mecha} eq $mecha} @{$ownership}
}

sub all_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my $user = $c->session('user');
    my @controlled = $db->get_collection('control')->find({ player => $user})->all();
    if($mecha_name)
    {
        my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
        $c->render(json => { mecha => mecha_from_mongo_to_json($mecha) });
    }
    else
    {
        my @mecha = $db->get_collection('mechas')->find()->all();
        my @out = ();
        for(@mecha)
        {
            if(owned($_->{name}, \@controlled))
            {
                push @out, mecha_from_mongo_to_json($_);
            }
        }
        $c->render(json => { mechas => \@out });
    }
}

sub _get_sighted_mechas
{
    my $game = shift;
    my $mecha_name = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $sighting_matrix ) = $db->get_collection('status')->find({ status_element => 'sighting_matrix' })->all();
    my @sighted;
    for(keys %{$sighting_matrix->{$mecha_name}})
    {
        if(exists $sighting_matrix->{$mecha_name}->{$_} && $sighting_matrix->{$mecha_name}->{$_} > 0)
        {
            push @sighted, $_;
        }
    }
    my @mecha = $db->get_collection('mechas')->find({ name => { '$in' => \@sighted }})->all();
    return @mecha;
}

sub sighted_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my @mecha = _get_sighted_mechas($game, $mecha_name);
    my @out = ();
    for(@mecha)
    {
        push @out, mecha_from_mongo_to_json($_);
    }
    $c->render(json => { mechas => \@out });
}

sub all_waypoints {
    my $c = shift;
    my $game = $c->param('game');
    my $wp_name = $c->param('waypoint');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    if($wp_name)
    {
        my ( $wp ) = $db->get_collection('map')->find({ type => 'waypoint', name => $wp_name } )->all();
        $c->render(json => { waypoint => waypoint_from_mongo_to_json($wp) });
    }
    else
    {
        my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
        my @out = ();
        for(@wp)
        {
            push @out, waypoint_from_mongo_to_json($_);
        }
        $c->render(json => { waypoints => \@out });
    }
}

sub all_visible {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);

    my @out = ();
    my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
    for(@wp)
    {
        my $w = waypoint_from_mongo_to_json($_);
        $w->{label} = $w->{name} . ' (W)';
        push @out, $w;
    }
    my @mecha = _get_sighted_mechas($game, $mecha_name);
    for(@mecha)
    {
        my $m_mongo = $_;
        my $m = mecha_from_mongo_to_json($m_mongo);
        $m->{label} = $m->{name} . ' (M)';
        push @out, $m;
    }
    $c->render(json => { elements => \@out });
}

sub all_hotspots {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $action = $c->param('action');
    my $type = $c->param('type');
    my $id = $c->param('id');

    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
    if($type && $id)
    {
        my ( $hot ) = $db->get_collection('map')->find({ type => $type, id => $id } )->sort({id => 1, type => 1})->all();
        $c->render(json => { hotspot => hotspot_from_mongo_to_json($hot, $mecha) });
    }
    else
    {
        my @hs = $db->get_collection('map')->find()->all();
        my @out = ();
        for(@hs)
        {
            my $hs_data = hotspot_from_mongo_to_json($_, $mecha);
            my $to_add = 1;
            if($hs_data->{map_type} eq 'waypoint')
            {
                $to_add = 0;
            }
            if($action && $action eq 'land' && 
                (($hs_data->{map_type} ne 'asteroid') || 
                ($hs_data->{map_type} eq 'asteroid' && $hs_data->{distance} > LANDING_RANGE)))
            {
                $to_add = 0;
            }
            push @out, $hs_data if $to_add;
        }
        $c->render(json => { hotspots => \@out });
    }
}

sub add_command
{
    my $c = shift;
    my $params = $c->req->json;

    my $client = MongoDB->connect();
    $c->app->log->debug(Dumper($params));
    my $db = $client->get_database('gunpla_' . $params->{game});

    my ( $timestamp_mongo ) = $db->get_collection('status')->find({ status_element => 'timestamp' })->all();
    my $timestamp = $timestamp_mongo->{timestamp};
    
    my ( $configured_command ) = $db->get_collection('available_commands')->find({ code => $params->{command} })->all();
    if($configured_command)
    {
        $params->{command} = $configured_command->{label};
    }

    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $params->{mecha} })->all();
    if(! $mecha->{waiting}) #Strong enough?
    {
        $c->render(json => { result => 'error', description => 'mecha not waiting for commands'});
    }
    else
    {
        $c->app->log->debug("Adding command " . $params->{mecha} . '-' . $mecha->{cmd_index});
        $db->get_collection('commands')->insert_one({ timestamp => $timestamp,
                                                      command   => $params->{command},
                                                      params    => $params->{params},
                                                      secondarycommand   => $params->{secondarycommand},
                                                      secondaryparams    => $params->{secondaryparams},
                                                      velocity    => $params->{velocity},
                                                      mecha     => $params->{mecha},
                                                      cmd_index => $mecha->{cmd_index} });
        $db->get_collection('mechas')->update_one( { 'name' => $params->{mecha} }, { '$set' => { 'waiting' => 0 } } );
        $c->render(json => { result => 'OK',
                             command => { command => $params->{command},
                                          params  => $params->{params},
                                          mecha   => $params->{mecha},
                                          secondarycommand => $params->{secondarycommand},
                                          secondaryparams => $params->{secondaryparams},
                                          velocity    => $params->{velocity},
                            } });


    }
}

sub read_command
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $prev = $c->param('prev') || 0;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
    my $cmd_index = $mecha->{cmd_index};
    $cmd_index-- if $prev;
    $c->app->log->debug("Getting command " . $mecha->{name} . '-' . $cmd_index);
    my ( $command ) = $db->get_collection('commands')->find({ mecha => $mecha->{name}, cmd_index => $cmd_index })->all();
    $c->render(json => { command => { command => $command->{command},
                                      params  => $command->{params},
                                      mecha   => $command->{mecha},
                                      secondarycommand => $command->{secondarycommand},
                                      secondaryparams => $command->{secondaryparams},
                                      velocity    => $command->{velocity}}});
}

sub read_event
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    #my $index = $c->param('index');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
    my $index = $mecha->{cmd_index};
    $c->app->log->debug("Getting event " . $mecha_name . '-' . $index);
    my @events = $db->get_collection('events')->find({ mecha => $mecha_name, cmd_index => int($index), blocking => 1})->all();
    my @out = ();
    for(@events)
    {
        push @out, { message => $_->{message},
                     mecha   => $_->{mecha} };
    }

    $c->render(json => { events => \@out });
}

sub available_commands
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my @commands_mongo = $db->get_collection('available_commands')->find(undef)->sort({code => 1})->all();
    
    my @commands = ();
    foreach my $c (@commands_mongo)
    {
        my $yes = 1;
        for(@{$c->{conditions}})
        {
            #No conditions defined yet
        }
        if($yes)
        {
            push @commands, command_from_mongo_to_json($c, $mecha_name, $game);
        }
    }
    $c->render(json => { commands => \@commands });
}

sub command_details
{
    my $c = shift;
    my $game = $c->param('game');
    my $command = $c->param('command');
    my $mecha_name = $c->param('mecha');
    
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $command_details ) = $db->get_collection('available_commands')->find({ code => $command })->all();
    
    if($command_details->{machinegun})
    { 
        my @mecha = _get_sighted_mechas($game, $mecha_name);
        if(@mecha == 0)
        {
            $command_details->{machinegun} = 0;
        }
    }
    $c->render(json => { command => command_from_mongo_to_json($command_details, $mecha_name, $game) });
}


1;
