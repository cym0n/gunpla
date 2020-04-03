package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;

sub all_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    if($mecha_name)
    {
        my ( $mecha ) = $db->get_collection('mecha')->find({ name => $mecha_name })->all();
        $c->render(json => { mecha => {  name     => $mecha->{name},
                                         faction  => $mecha->{faction},
                                         position => $mecha->{position},
                                         waiting  => $mecha->{waiting} } });
    }
    else
    {
        my @mecha = $db->get_collection('mecha')->find()->all();
        my @out = ();
        for(@mecha)
        {
            push @out, { name     => $_->{name},
                        faction  => $_->{faction},
                        position => $_->{position},
                        waiting  => $_->{waiting} }
        }
        $c->render(json => { mechas => \@out });
    }
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
    $c->app->log->debug("Adding command");
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $params->{game});
    my ( $mecha ) = $db->get_collection('mecha')->find({ name => $params->{mecha} })->all();
    if(! $mecha->{waiting}) #Strong enough?
    {
        $c->render(json => { result => 'error', description => 'mecha not waiting for commands'});
    }
    else
    {
        $db->get_collection('commands')->insert_one({ command => $params->{command},
                                                      params => $params->{params},
                                                      mecha => $params->{mecha},
                                                      cmd_index => $mecha->{cmd_index} });
        $db->get_collection('mecha')->update_one( { name => $params->{mecha} }, { '$set' => { 'waiting' => 1 } } );
        $c->render(json => { result => 'OK' });
    }
}

sub read_command
{
    my $c = shift;
    my $game = $c->param('game');
    my $mecha_name = $c->param('mecha');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my ( $mecha ) = $db->get_collection('mecha')->find({ name => $mecha_name })->all();
    my ( $command ) = $db->get_collection('commands')->find({ name => $mecha->{name}, cmd_index => $mecha->{cmd_index} })->all();
    $c->render(json => { command => { command => $command->{command},
                                      params => $command->{params},
                                      mecha => $command->{mecha} } });
}

1;
