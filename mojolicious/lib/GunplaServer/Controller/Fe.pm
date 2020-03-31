package GunplaServer::Controller::Fe;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub main {
  my $self = shift;

  $self->render();
}

1;
