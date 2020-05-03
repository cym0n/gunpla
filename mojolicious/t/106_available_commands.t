use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('duel.csv');
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("All commands retrieved by the API");
$t->get_ok('/game/available-commands?game=autotest&mecha=RX78')
    ->status_is(200)
    ->json_is({
          'commands' => [ 
                          {
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=visible',
                            'velocity' => 1,
                            'filter' => 'visible',
                            'label' => 'GET AWAY',
                            'machinegun' => 1,
                            'code' => 'away',
                            'params_label' => 'Select a Element'
                          },
                          {
                            'velocity' => 1,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=hotspots',
                            'machinegun' => 1,
                            'code' => 'flyhot',
                            'label' => 'FLY TO HOTSPOT',
                            'filter' => 'hotspots',
                            'params_label' => 'Select a Hotspot'
                          },
                          {
                            'label' => 'FLY TO MECHA',
                            'filter' => 'sighted-by-faction',
                            'code' => 'flymec',
                            'machinegun' => 1,
                            'velocity' => 1,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction',
                            'params_label' => 'Select a Mecha'
                          },
                          {
                            'params_label' => 'Select a Waypoint',
                            'label' => 'FLY TO WAYPOINT',
                            'filter' => 'waypoints',
                            'code' => 'flywp',
                            'machinegun' => 1,
                            'velocity' => 1,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=waypoints'
                          },
                          {
                            'params_label' => 'Select a Hotspot',
                            'filter' => 'landing',
                            'label' => 'LAND',
                            'code' => 'land',
                            'machinegun' => 0,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=landing',
                            'velocity' => 0
                          },
                          {
                            'params_label' => 'Select a Mecha',
                            'machinegun' => 0,
                            'code' => 'rifle',
                            'label' => 'RIFLE',
                            'filter' => 'sighted-by-faction',
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction',
                            'velocity' => 0
                          },
                          {
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction',
                            'velocity' => 0,
                            'code' => 'sword',
                            'machinegun' => 0,
                            'label' => 'SWORD ATTACK',
                            'filter' => 'sighted-by-faction',
                            'params_label' => 'Select a Mecha'
                          }
                        ]
           });
Gunpla::Test::dump_api($t);

diag("FLY TO WAYPOINT details");
$t->get_ok('/game/available-commands?game=autotest&mecha=RX78&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'params_label' => 'Select a Waypoint',
                          'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=waypoints',
                          'filter' => 'waypoints',
                          'machinegun' => 1,
                          'velocity' => 1
                        }
    });

Gunpla::Test::clean_db('autotest', 1);

done_testing();
