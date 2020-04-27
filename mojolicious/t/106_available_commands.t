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

diag("No mecha sighted, FLY TO WAYPOINT and GET AWAY are the only available command");
$t->get_ok('/game/available-commands?game=autotest&mecha=RX78')
    ->status_is(200)
    ->json_is({
          'commands' => [ 
                          {
                            'velocity' => 1,
                            'label' => 'GET AWAY',
                            'code' => 'away',
                            'params_label' => 'Select a Element',
                            'params_callback' => '/game/visible-elements?game=autotest&mecha=RX78',
                            'conditions' => [],
                            'params_masternode' => 'elements',
                            'machinegun' => 1
                          },
                          {
                            'velocity' => 1,
                            'code' => 'flyhot',
                            'label' => 'FLY TO HOTSPOT',
                            'params_label' => 'Select a Hotspot',
                            'params_callback' => '/game/hotspots?game=autotest&mecha=RX78',
                            'conditions' => [],
                            'params_masternode' => 'hotspots',
                            'machinegun' => 1
                          },
                          {
                            'conditions' => [],
                            'params_masternode' => 'mechas',
                            'machinegun' => 1,
                            'label' => 'FLY TO MECHA',
                            'code' => 'flymec',
                            'velocity' => 1,
                            'params_callback' => '/game/sighted?game=autotest&mecha=RX78',
                            'params_label' => 'Select a Mecha'
                          },
                          {
                            'params_callback' => '/game/waypoints?game=autotest',
                            'params_label' => 'Select a Waypoint',
                            'label' => 'FLY TO WAYPOINT',
                            'code' => 'flywp',
                            'velocity' => 1,
                            'machinegun' => 1,
                            'params_masternode' => 'waypoints',
                            'conditions' => []
                          },
                          {
                            'params_label' => 'Select a Hotspot',
                            'params_callback' => '/game/hotspots?game=autotest&mecha=RX78&action=land',
                            'velocity' => 0,
                            'code' => 'land',
                            'label' => 'LAND',
                            'params_masternode' => 'hotspots',
                            'machinegun' => 0,
                            'conditions' => []
                          },
                          {
                            'conditions' => [],
                            'machinegun' => 0,
                            'params_masternode' => 'mechas',
                            'label' => 'RIFLE',
                            'code' => 'rifle',
                            'velocity' => 0,
                            'params_label' => 'Select a Mecha',
                            'params_callback' => '/game/sighted?game=autotest&mecha=RX78'
                          },
                          {
                            'params_label' => 'Select a Mecha',
                            'params_callback' => '/game/sighted?game=autotest&mecha=RX78',
                            'code' => 'sword',
                            'label' => 'SWORD ATTACK',
                            'velocity' => 0,
                            'machinegun' => 0,
                            'params_masternode' => 'mechas',
                            'conditions' => []
                          }
                        ]
           });
Gunpla::Test::dump_api($t);

diag("FLY TO WAYPOINT details - machinegun is off");
$t->get_ok('/game/command-details?game=autotest&mecha=RX78&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'conditions' => [  ],
                          'params_label' => 'Select a Waypoint',
                          'params_callback' => '/game/waypoints?game=autotest',
                          'params_masternode' => 'waypoints',
                          'machinegun' => 0,
                          'velocity' => 1
                        }
    });

diag("Generate a world with a target sighted and save it on db");
$world = Gunpla::Test::test_bootstrap('dummy.csv');
my $t2 = Test::Mojo->new('GunplaServer');

diag("Available-commands give back always the same result");
diag("FLY TO WAYPOINT details - machinegun is on");
$t2->get_ok('/game/command-details?game=autotest&mecha=RX78&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'conditions' => [  ],
                          'params_label' => 'Select a Waypoint',
                          'params_callback' => '/game/waypoints?game=autotest',
                          'params_masternode' => 'waypoints',
                          'machinegun' => 1,
                          'velocity' => 1
                        }
    });
diag("FLY TO MECHA details - machinegun is on");
$t2->get_ok('/game/command-details?game=autotest&mecha=RX78&command=flymec')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flymec',
                          'label' => 'FLY TO MECHA',
                          'conditions' => [  ],
                          'params_label' => 'Select a Mecha',
                          'params_callback' => '/game/sighted?game=autotest&mecha=RX78',
                          'params_masternode' => 'mechas',
                          'machinegun' => 1,
                          'velocity' => 1,
                        }
    });

Gunpla::Test::clean_db('autotest', 1);

done_testing();
