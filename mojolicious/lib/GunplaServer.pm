package GunplaServer;
use Mojo::Base 'Mojolicious';

use MongoDB;

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

  $self->app->hook(before_dispatch => sub {
    my $c = shift;
    if($c->param('mecha'))
    {
        my $mecha = $c->param('mecha');
        my $game = $c->param('game');
        my $client = MongoDB->connect();
        my $db = $client->get_database('gunpla_' . $game);
        my $user = $c->session('user');
        my ( $controlled ) = $db->get_collection('control')->find({ player => $user, mecha => $mecha })->all();
        if(! $controlled)
        {
            say "Not Allowed call for $user";
            $c->render(json => { error => 'Mecha not owned' }, status => 403)
        }
    }


  });




  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/fe/login')->to('fe#login');
  $r->post('/fe/login')->to('fe#to_the_game');
  $r->get('/fe/game')->to('fe#main');
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
