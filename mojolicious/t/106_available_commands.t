use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Position;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world with no target sighted and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init_test('duel');
my $t = Test::Mojo->new('GunplaServer');
diag("No mecha sighted, FLY TO WAYPOINT is the only available command");
$t->get_ok('/game/available-commands?game=autotest&mecha=Diver')
    ->status_is(200)
    ->json_is({
          'commands' => [ {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT'
                        }, ]
           });

diag("FLY TO WAYPOINT details");
$t->get_ok('/game/command-details?game=autotest&mecha=Diver&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'conditions' => [  ],
                          'params_label' => 'Select a Waypoint',
                          'params_callback' => '/game/waypoints?game=autotest',
                          'params_masternode' => 'waypoints',
                          'machinegun' => 0
                        }
    });

$db->drop();
diag("Generate a world with a target sighted and save it on db");
$world = Gunpla::World->new(name => 'autotest');
diag("Stimulating sight matrix generation");
$world->init_test('dummy');
$world->armies->[0]->waiting(0);
$world->add_command('Diver', 'WAITING');
$world->armies->[1]->waiting(0);
$world->add_command('Dummy', 'WAITING');
is($world->action(), 1);
$world->save();

my $t2 = Test::Mojo->new('GunplaServer');
diag("Mecha sighted, all commands available");
$t2->get_ok('/game/available-commands?game=autotest&mecha=Diver')
    ->status_is(200)
    ->json_is({
          'commands' => [
                        {
                          'code' => 'flymec',
                          'label' => 'FLY TO MECHA'
                        },
                        {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT'
                        }, 
                        {
                          'code' => 'sword',
                          'label' => 'SWORD ATTACK'
                        }]
           });

diag("FLY TO WAYPOINT details");
$t2->get_ok('/game/command-details?game=autotest&mecha=Diver&command=flywp')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flywp',
                          'label' => 'FLY TO WAYPOINT',
                          'conditions' => [  ],
                          'params_label' => 'Select a Waypoint',
                          'params_callback' => '/game/waypoints?game=autotest',
                          'params_masternode' => 'waypoints',
                          'machinegun' => 1
                        }
    });
diag("FLY TO MECHA details");
$t2->get_ok('/game/command-details?game=autotest&mecha=Diver&command=flymec')
    ->status_is(200)
    ->json_is({
          'command' => {
                          'code' => 'flymec',
                          'label' => 'FLY TO MECHA',
                          'conditions' => [ 'sighted_foe' ],
                          'params_label' => 'Select a Mecha',
                          'params_callback' => '/game/sighted?game=autotest&mecha=Diver',
                          'params_masternode' => 'mechas',
                          'machinegun' => 1
                        }
    });
diag("Drop gunpla_autotest db");
$db = $mongo->get_database('gunpla_autotest');
#$db->drop();


done_testing();
