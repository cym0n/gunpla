use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Test::Mojo;
use Gunpla::Position;
use MongoDB;

diag("Main library load");
require_ok('Gunpla::World');

my $mongo = MongoDB->connect(); 

diag("Drop gunpla_autotest db on local mongodb");
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();

my $world = Gunpla::World->new(name => 'autotest');
$world->init_test('duel');

diag("Simulation of order received");
$world->armies->[0]->waiting(0);
$world->add_command('RX78', { command => 'FLY TO WAYPOINT', params => 'WP-center', velocity => 6 });
$world->armies->[1]->waiting(0);
$world->add_command('Hyakushiki', {command => 'FLY TO WAYPOINT', params => 'WP-center', velocity => 2});

diag("Action until sighting event");
is($world->action(), 1);

diag("Checking game status after the event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 10000);
is($world->armies->[0]->waiting, 1);
is($world->armies->[0]->cmd_index, 1);
is($world->armies->[0]->position->x, 68758);
is($world->armies->[1]->waiting, 0);
is($world->armies->[1]->cmd_index, 0);
is($world->armies->[1]->position->x, -71240);

diag("Checking event generation (using API)");
$world->save;
my $t = Test::Mojo->new('GunplaServer');
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 sighted Hyakushiki'
            }
        ]
    }
);
diag("Flying away from Hyakushiki");
$world->armies->[0]->waiting(0);
$world->add_command('RX78', { command => 'FLY TO WAYPOINT', params => 'WP-blue', velocity => 6 });

diag("Action until lost contact event");
is($world->action(), 1);

diag("Checking game status after the event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 0, "RX78 Sighting matrix");
is($world->armies->[0]->waiting, 1, "RX79 Waiting");
is($world->armies->[0]->cmd_index, 2, "RX78 CMD index");
is($world->armies->[0]->position->x, 70444, "RX78 X position");
is($world->armies->[1]->waiting, 0, "Hyakushiki Waiting");
is($world->armies->[1]->cmd_index, 0, "Hyakushiki CMD index");
is($world->armies->[1]->position->x, -70217, "Hyakushiki X position");
diag("Checking event generation (using API)");
$world->save;
my $t2 = Test::Mojo->new('GunplaServer');
$t2->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 lost contact with Hyakushiki'
            }
        ]
    }
);



diag("MongoDB cleanup");
$db->drop();



done_testing();

