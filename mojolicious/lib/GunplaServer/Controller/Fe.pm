package GunplaServer::Controller::Fe;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;

# This action will render a template
sub main {
    my $c = shift;
    my $game = $c->param('game');
    $c->render(game => $game);
}

sub login {
    my $c = shift;
    my $client = MongoDB->connect();
    my $db = $client->get_database('gunpla__core'); 
    my @games = $db->get_collection('games')->find()->all();
    $c->stash(games => \@games);
    $c->render();
}

sub to_the_game {
    my $c = shift;
    my $user = $c->param('user');
    my $game = $c->param('game');
    $c->session(user => $user);
    my $url = $c->url_for("/fe/game");
    $c->redirect_to($url->query(game => $game));
}


1;
