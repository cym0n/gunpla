package GunplaServer::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;

sub all_mechas {
    my $c = shift;
    my $game = $c->param('game');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my @mecha = $db->get_collection('mecha')->find()->all();
    $c->render(json => { mechas => \@mecha });
}

sub all_waypoints {
    my $c = shift;
    my $game = $c->param('game');
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla_' . $game);
    my @wp = $db->get_collection('map')->find({ type => 'waypoint' } )->all();
    $c->render(json => { waypoints => \@wp });
}

1;
