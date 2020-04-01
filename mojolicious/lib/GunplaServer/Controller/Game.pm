package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;

sub all_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    #TODO: get rid of the not interesting informations
    #TODO: implemente the fetch for just one mecha
    my @mecha = $db->get_collection('mecha')->find()->all();
    $c->render(json => { mechas => \@mecha });
}

sub all_waypoints {
    my $c = shift;
    my $game = $c->param('game');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    #TODO: get rid of the not interesting informations
    #TODO: implemente the fetch for just one waypoint 
    my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
    $c->render(json => { waypoints => \@wp });
}

sub add_command
{
    my $c = shift;
    my $params = $c->req->json;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $params->{game});
    #TODO: verifiy no other commands are present for that mecha
    #Put the mecha on waiting
    $db->get_collection('commands')->insert_one({   command => $params->{command},
                                                    params => $params->{params},
                                                    mecha => $params->{mecha} });
    $c->render(json => { result => 'OK' });
}

1;
