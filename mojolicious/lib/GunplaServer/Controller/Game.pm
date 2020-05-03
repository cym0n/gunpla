package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use lib "../../";

use MongoDB;
use Gunpla::Constants ':all';
use Gunpla::Utils qw(controlled target_from_mongo_to_json mecha_from_mongo_to_json sighted_by_me sighted_by_faction command_from_mongo_to_json);
use Gunpla::Position;
use Data::Dumper;


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
            if(controlled($game, $_->{name}, $user))
            {
                push @out, mecha_from_mongo_to_json($_);
            }
        }
        $c->render(json => { mechas => \@out });
    }
}

sub targets
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha = $c->param('mecha');
    my $filter = $c->param('filter');

    my @to_take = ();
    my @out = ();

    @to_take = keys %{FILTERS->{$filter}};
    if(! @to_take)
    {
        $c->render(json => { error => 'Bad filter provided' }, status => 400)
    }

    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);

    for(@to_take)
    {
        if($_ eq 'waypoints')    
        {
            my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->sort({id => 1, type => 1})->all();
            for(@wp)
            {
                my $w = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $w;
            }
        }
        elsif($_ eq 'hotspots')    
        {
            my @wp = $db->get_collection('map')->find({ type => 'asteroid' } )->sort({id => 1, type => 1})->all();
            for(@wp)
            {
                my $w = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $w;
            }
        }
        elsif($_ eq 'map_elements')
        {
            my @me = $db->get_collection('map')->find()->sort({id => 1, type => 1})->all();
            for(@me)
            {
                my $mp = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $mp;
            }
        }
        elsif($_ eq 'landing')
        {
            my @me = $db->get_collection('map')->find({ type => 'asteroid' })->sort({id => 1, type => 1})->all();
            for(@me)
            {
                my $mp = target_from_mongo_to_json($game, $mecha, 'map', $_);
                if($mp->{distance} < LANDING_RANGE)
                {
                    push @out, $mp;
                }
            }
        }
        elsif($_ eq 'sighted_by_me')
        {
            my @mec = $db->get_collection('mechas')->find()->sort({name => 1})->all();
            for(@mec)
            {
                if(sighted_by_me($game, $mecha, $_))
                {
                    my $m = target_from_mongo_to_json($game, $mecha, 'mechas', $_);
                    push @out, $m;
                }
            }
        }
        elsif($_ eq 'sighted_by_faction')
        {
            my @mec = $db->get_collection('mechas')->find()->sort({name => 1})->all();
            for(@mec)
            {
                if(sighted_by_faction($game, $mecha, $_))
                {
                    my $m = target_from_mongo_to_json($game, $mecha, 'mechas', $_);
                    push @out, $m;
                }
            }
        }
    }
    $c->render(json => { targets => \@out });
    
}

sub game_commands
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $command = $c->param('command');
   
    my $query = undef;
    my $node = 'commands';
    if($command)
    {
        $node = 'command';
        $query = { code => $command };
    }
 
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my @commands_mongo = $db->get_collection('available_commands')->find($query)->sort({code => 1})->all();
    
    my @commands = ();
    foreach my $c (@commands_mongo)
    {
        push @commands, command_from_mongo_to_json($c, $mecha_name, $game);
    }
    if($node eq 'command')
    {
        $c->render(json => { $node => $commands[0] });
    }
    elsif($node eq 'commands')
    {
        $c->render(json => { $node => \@commands });
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


1;
