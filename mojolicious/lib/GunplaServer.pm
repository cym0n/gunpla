package GunplaServer;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  $self->defaults(layout => 'default');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/fe')->to('fe#main');
  $r->get('/game/mechas')->to('game#all_mechas');
  $r->get('/game/sighted')->to('game#sighted_mechas');
  $r->get('/game/waypoints')->to('game#all_waypoints');
  $r->get('/game/hotspots')->to('game#all_hotspots');
  $r->get('/game/visible-elements')->to('game#all_visible');
  $r->get('/game/event')->to('game#read_event');
  $r->get('/game/command')->to('game#read_command');
  $r->post('/game/command')->to('game#add_command');
  $r->get('/game/available-commands')->to('game#available_commands');
  $r->get('/game/command-details')->to('game#command_details');
}

1;
