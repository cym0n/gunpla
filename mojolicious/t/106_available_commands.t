use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../stand-alone/lib';
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
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=hotspots&min-distance=1000',
                            'machinegun' => 1,
                            'code' => 'flyhot',
                            'label' => 'FLY TO HOTSPOT',
                            'filter' => 'hotspots',
                            'params_label' => 'Select a Hotspot',
                            'min_distance' => 1000,
                          },
                          {
                            'label' => 'FLY TO MECHA',
                            'filter' => 'sighted-by-faction',
                            'code' => 'flymec',
                            'machinegun' => 1,
                            'velocity' => 1,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction&min-distance=1000',
                            'params_label' => 'Select a Mecha',
                            'min_distance' => 1000,
                          },
                          {
                            'params_label' => 'Select a Waypoint',
                            'label' => 'FLY TO WAYPOINT',
                            'filter' => 'waypoints',
                            'code' => 'flywp',
                            'machinegun' => 1,
                            'velocity' => 1,
                            'min_distance' => 0,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=waypoints&min-distance=0',
                          },
                          {
                            'machinegun' => 0,
                            'params_callback' => undef,
                            'params_label' => 'Select time interval',
                            'label' => 'GUARD',
                            'code' => 'guard',
                            'filter' => undef,
                            'values' => {
                                          '50000' => '50000',
                                          '20000' => '20000',
                                          '70000' => '70000'
                                        },
                            'velocity' => 0,
                            'min_distance' => 0
                          },
                          {
                            'params_label' => 'Select a Hotspot',
                            'filter' => 'landing',
                            'label' => 'LAND',
                            'code' => 'land',
                            'machinegun' => 0,
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=landing&min-distance=0&max-distance=20000',
                            'velocity' => 0,
                            'max_distance' => 20000,
                            'min_distance' => 0,
                          },
                          {
                            code => 'last',
                            label => 'FLY TO LAST KNOWN POSITION',
                            filter => 'last-sight',
                            params_label => 'Select a Mecha',
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=last-sight&min-distance=0',
                            machinegun => 1,
                            velocity => 1,
                            min_distance => 0
                          },
                          {
                            'params_label' => 'Select a Mecha',
                            'machinegun' => 0,
                            'code' => 'rifle',
                            'label' => 'RIFLE',
                            'filter' => 'sighted-by-faction',
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction',
                            'velocity' => 0,
                            'energy_needed' => 3
                          },
                          { 
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=friends-no-wait',
                            'velocity' => 0,
                            'code' => 'support',
                            'machinegun' => 0,
                            'label' => 'ASK SUPPORT',
                            'filter' => 'friends-no-wait',
                            'params_label' => 'Select friendly Mecha',
                          },
                          {
                            'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=sighted-by-faction',
                            'velocity' => 0,
                            'code' => 'sword',
                            'machinegun' => 0,
                            'label' => 'SWORD ATTACK',
                            'filter' => 'sighted-by-faction',
                            'params_label' => 'Select a Mecha',
                            'energy_needed' => 5
                          }
                        ]
           });
Gunpla::Test::dump_api($t);

diag("flywp details");
$t->get_ok('/game/available-commands?game=autotest&mecha=RX78&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'params_label' => 'Select a Waypoint',
                          'min_distance' => 0,
                          'params_callback' => '/game/targets?game=autotest&mecha=RX78&filter=waypoints&min-distance=0',
                          'filter' => 'waypoints',
                          'machinegun' => 1,
                          'velocity' => 1
                        }
    });

Gunpla::Test::clean_db('autotest', 1);

done_testing();
