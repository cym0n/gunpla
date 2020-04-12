package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use Data::Dumper;

sub from_mongo_to_json
{
    my $mecha = shift;
    return { name     => $mecha->{name},
             life     => $mecha->{life},
             faction  => $mecha->{faction},
             position => $mecha->{position},
             waiting  => $mecha->{waiting} };
}

sub all_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    if($mecha_name)
    {
        my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
        $c->render(json => { mecha => from_mongo_to_json($mecha) });
    }
    else
    {
        my @mecha = $db->get_collection('mechas')->find()->all();
        my @out = ();
        for(@mecha)
        {
            push @out, from_mongo_to_json($_);
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
        push @out, from_mongo_to_json($_);
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
        $c->render(json => { waypoint => { name => $wp->{name},
                                           x    => $wp->{position}->{x},
                                           y    => $wp->{position}->{y},
                                           z    => $wp->{position}->{z} } });
    }
    else
    {
        my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
        my @out = ();
        for(@wp)
        {
            push @out, { name => $_->{name},
                        x => $_->{position}->{x},
                        y => $_->{position}->{y},
                        z => $_->{position}->{z}, };
        }
        $c->render(json => { waypoints => \@out });
    }
}

sub add_command
{
    my $c = shift;
    my $params = $c->req->json;

    my $client = MongoDB->connect();
    $c->app->log->debug(Dumper($params));
    my $db = $client->get_database('gunpla_' . $params->{game});
    
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
        $db->get_collection('commands')->insert_one({ command   => $params->{command},
                                                      params    => $params->{params},
                                                      secondarycommand   => $params->{secondarycommand},
                                                      secondaryparams    => $params->{secondaryparams},
                                                      mecha     => $params->{mecha},
                                                      cmd_index => $mecha->{cmd_index} });
        $db->get_collection('mechas')->update_one( { 'name' => $params->{mecha} }, { '$set' => { 'waiting' => 0 } } );
        $c->render(json => { result => 'OK',
                             command => { command => $params->{command},
                                          params  => $params->{params},
                                          mecha   => $params->{mecha},
                                          secondarycommand => $params->{secondarycommand},
                                          secondaryparams => $params->{secondaryparams},
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
                                      secondaryparams => $command->{secondaryparams}}});
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
    my @events = $db->get_collection('events')->find({ mecha => $mecha_name, cmd_index => int($index)})->all();
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
            if($_ eq 'sighted_foe')
            {
                my @mecha = _get_sighted_mechas($game, $mecha_name);
                $yes = 0 if(@mecha == 0);
            }
        }
        if($yes)
        {
            push @commands, { code => $c->{code}, label => $c->{label} }
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
    
    my $callback = $command_details->{params_callback};
    $callback =~ s/%%GAME%%/$game/;
    $callback =~ s/%%MECHA%%/$mecha_name/;
    $command_details->{params_callback} = $callback;
    if($command_details->{machinegun})
    { 
        my @mecha = _get_sighted_mechas($game, $mecha_name);
        if(@mecha == 0)
        {
            $command_details->{machinegun} = 0;
        }
    }
    delete $command_details->{_id};
    $c->render(json => { command => $command_details });
}


1;
