package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use lib "../../";

use MongoDB;
use Gunpla::Constants ':all';
use Gunpla::Utils qw(controlled target_from_mongo_to_json mecha_from_mongo_to_json sighted_by_me sighted_by_faction command_from_mongo_to_json get_from_id);
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
    my $min_distance = $c->param('min-distance');
    my $max_distance = $c->param('max-distance');

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
            my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
            for(@wp)
            {
                my $w = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $w;
            }
        }
        elsif($_ eq 'hotspots')    
        {
            my @wp = $db->get_collection('map')->find({ type => 'asteroid' } )->all();
            for(@wp)
            {
                my $w = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $w;
            }
        }
        elsif($_ eq 'map_elements')
        {
            my @me = $db->get_collection('map')->find()->all();
            for(@me)
            {
                my $mp = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $mp;
            }
        }
        elsif($_ eq 'landing')
        {
            my @me = $db->get_collection('map')->find({ type => 'asteroid' })->all();
            for(@me)
            {
                my $mp = target_from_mongo_to_json($game, $mecha, 'map', $_);
                push @out, $mp;
            }
        }
        elsif($_ eq 'sighted_by_me')
        {
            my @mec = $db->get_collection('mechas')->find()->all();
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
            my @mec = $db->get_collection('mechas')->find()->all();
            for(@mec)
            {
                if(sighted_by_faction($game, $mecha, $_))
                {
                    my $m = target_from_mongo_to_json($game, $mecha, 'mechas', $_);
                    push @out, $m;
                }
            }
        }
        elsif($_ eq 'last_sight')
        {
            my ( $the_mecha ) = $db->get_collection('mechas')->find({ name => $mecha })->all();
            my $target = undef;
        
            if((! $the_mecha->{movement_target} || ! $the_mecha->{movement_target}->{type} eq 'none') && $the_mecha->{attack_target} && $the_mecha->{attack_target}->{type} eq 'mecha') 
            {
                $target =  $the_mecha->{attack_target}
            }
            elsif($the_mecha->{movement_target} && $the_mecha->{movement_target}->{type} eq 'mecha') 
            {
                $target =  $the_mecha->{movement_target}
            }
            if($target)
            {
                my ( $target_mecha ) = $db->get_collection('mechas')->find({ name => $target->{name} })->all();
                if($target_mecha && ! sighted_by_faction($game, $mecha, $target_mecha))
                {
                    push @out, target_from_mongo_to_json($game, $mecha, 'position', { id => 0, label => $target_mecha->{name}, position => $the_mecha->{destination} });
                }
            }
        }
    }
    if(defined $c->param('min-distance'))
    {
        @out = grep { $_->{distance} > $c->param('min-distance')} @out;
    }
    if(defined $c->param('max-distance'))
    {
        @out = grep { $_->{distance} < $c->param('max-distance')} @out;
    }
    @out = sort { $a->{world_id} cmp $b->{world_id} } @out;
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
    foreach my $com (@commands_mongo)
    {
        push @commands, command_from_mongo_to_json($com, $mecha_name, $game);
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

sub traffic_light
{
    my $c = shift;
    my $game = $c->param('game');
    my $user = $c->session('user');
    my $out = 'GREEN';
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my @mecha = $db->get_collection('mechas')->find()->all();
    for(@mecha)
    {
        if($_->{waiting} == 1)
        {
            if(controlled($game, $_->{name}, $user))
            {
                $c->render(json => { status => 'RED' });
                return;
            }
            else
            {
                $out = 'YELLOW';
            }
        }
    }
    $c->render(json => { status => $out });
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

    if(! $configured_command)
    {
        $c->render(json => { result => 'error', description => 'bad command code'}, status => 400);
        return;
    }
    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $params->{mecha} })->all();
    my $mecha_data =  mecha_from_mongo_to_json($mecha);
    if($configured_command->{velocity})
    {
        if( ! $params->{velocity} )
        {
            $c->render(json => { result => 'error', description => 'bad command: velocity needed'}, status => 400);
            return;
        }
        if($params->{velocity} > $mecha_data->{available_max_velocity})
        {
            $c->render(json => { result => 'error', description => 'bad command: velocity not allowed'}, status => 400);
            return;
        }
    }

    if(! $mecha->{waiting}) #Strong enough?
    {
        $c->render(json => { result => 'error', description => 'mecha not waiting for commands'}, status => 403);
        return;
    }

    my @to_take = keys %{FILTERS->{$configured_command->{filter}}};
    my @allowed_targets = (); 
    for(@to_take)
    {
        @allowed_targets = (@allowed_targets, @{FILTERS->{$configured_command->{filter}}->{$_}});
    }
    my ($target_type, $target_id) = split('-', $params->{params});
    if(! grep {$_ eq $target_type} @allowed_targets)
    {
        $c->render(json => { result => 'error', description => 'bad target provided: ' . $params->{params}}, status => 400);
        return;
    }
    my $target_obj = get_from_id($params->{game}, $params->{params});

    my $ok = 1;
    if($configured_command->{filter} eq 'sighted-by-me')
    {
        $ok = sighted_by_me($params->{game}, $params->{mecha}, $target_obj);
    }
    elsif($configured_command->{filter} eq 'sighted-by-faction')
    {
        $ok = sighted_by_faction($params->{game}, $params->{mecha}, $target_obj);
    }
    elsif($configured_command->{filter} eq 'visible' && $target_type eq 'MEC')
    {   
        $ok = sighted_by_faction($params->{game}, $params->{mecha}, $target_obj);
    }
    my $mp = target_from_mongo_to_json($params->{game}, $params->{mecha}, 'map', $target_obj);
    if(exists $configured_command->{min_distance})
    {
        $ok = $ok && $mp->{distance} > $configured_command->{min_distance}
    }
    if(exists $configured_command->{max_distance})
    {
        $ok = $ok && $mp->{distance} < $configured_command->{max_distance}
    }
    if(! $ok)
    {
        $c->render(json => { result => 'error', description => 'Bad target provided: ' . $params->{params}}, status => 400);
        return;
    }
    if($params->{secondarycommand} && $params->{secondarycommand} eq 'machinegun' && ! $configured_command->{'machinegun'})
    {
        $c->render(json => { result => 'error', description => 'Bad command: machinegun not allowed' }, status => 400);
        return;
    }
    if($params->{secondarycommand} && $params->{secondarycommand} eq 'machinegun')
    {
        $ok = $params->{secondaryparams} =~ /^MEC/ && sighted_by_faction($params->{game}, $params->{mecha}, get_from_id($params->{game}, $params->{secondaryparams}));
    }
    if(! $ok)
    {
        $c->render(json => { result => 'error', description => 'Bad target provided: ' . $params->{secondaryparams}}, status => 400);
        return;
    }

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

#This is really used only in prev mode. 
sub read_command
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $prev = $c->param('prev') || 0;
    my $available = $c->param('available') || 0;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha ) = $db->get_collection('mechas')->find({ name => $mecha_name })->all();
    my $mecha_data =  mecha_from_mongo_to_json($mecha);
    my $cmd_index = $mecha->{cmd_index};
    $cmd_index-- if $prev;
    $c->app->log->debug("Getting command " . $mecha->{name} . '-' . $cmd_index);
    my ( $command ) = $db->get_collection('commands')->find({ mecha => $mecha->{name}, cmd_index => $cmd_index })->all();
    my $ok = 1;
    if($available)
    {
        my $target_obj = get_from_id($game, $command->{params});
        if($command->{params} =~ /^MEC/)
        {   
            $ok = sighted_by_faction($game, $mecha_name, $target_obj);
        }
        my ( $configured_command ) = $db->get_collection('available_commands')->find({ code => $command->{command} })->all();
        my $mp = target_from_mongo_to_json($game, $mecha_name, $target_obj->{source}, $target_obj);
        if(exists $configured_command->{min_distance})
        {
            $ok = $ok && $mp->{distance} > $configured_command->{min_distance}
        }
        if(exists $configured_command->{max_distance})
        {
            $ok = $ok && $mp->{distance} < $configured_command->{max_distance}
        }
        if($command->{velocity})
        {
            $ok = $ok && $command->{velocity} <= $mecha_data->{available_max_velocity};
        }
    }
    if($ok)
    {
        $c->render(json => { command => { command => $command->{command},
                                          params  => $command->{params},
                                          mecha   => $command->{mecha},
                                          secondarycommand => $command->{secondarycommand},
                                          secondaryparams => $command->{secondaryparams},
                                          velocity    => $command->{velocity}}});
    }
    else
    {
        $c->render(json => { command => { } });
    }
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
