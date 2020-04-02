package GunplaServer::Controller::Fe;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub main {
    my $c = shift;
    my $game = $c->param('game');
    $c->render(game => $game);
}

1;
