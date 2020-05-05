package GunplaServer;
use Mojo::Base 'Mojolicious';

use lib "../../";

use MongoDB;
use Gunpla::Utils qw(controlled);

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
    if($c->app->config->{no_login})
    {
        $self->app->log->debug('--- no login ---');
    }
    else
    {
        if($c->param('mecha'))
        {
            my $mecha = $c->param('mecha');
            my $game = $c->param('game');
            my $user = $c->session('user');
            if(! controlled($game, $mecha, $user))
            {
                $self->app->log->debug("Not Allowed call for $user");
                $c->render(json => { error => 'Mecha not owned' }, status => 403)
            }
        }
    }
  });




  # Normal route to controller
  $r->get('/')->to('fe#hp');
  $r->get('/fe/login')->to('fe#login');
  $r->post('/fe/login')->to('fe#to_the_game');
  $r->get('/fe/game')->to('fe#main');
  $r->get('/game/mechas')->to('game#all_mechas');
  $r->get('/game/targets')->to('game#targets');
  $r->get('/game/traffic-light')->to('game#traffic_light');
  $r->get('/game/event')->to('game#read_event');
  $r->get('/game/command')->to('game#read_command');
  $r->post('/game/command')->to('game#add_command');
  $r->get('/game/available-commands')->to('game#game_commands');
}

1;
