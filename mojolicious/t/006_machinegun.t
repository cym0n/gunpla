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


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest', dice_results => [20, 3, 20]);
$world->init_test('dummy');

my $t = Test::Mojo->new('GunplaServer');

resume(1);
diag("=== RX78 sees dummy at start");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 sighted Dummy'
            }
        ]
    }
);

resume(1);
diag("=== First shot");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'RX78 hits with machine gun Dummy'
            }
        ]
    }
);
diag("Checking mechas stats");
is($world->armies->[0]->position->x, 1000);
is($world->armies->[0]->velocity, 10);
is($world->armies->[0]->attack_limit, 2);
is($world->armies->[0]->gauge, 0);
is($world->armies->[1]->life, 980);

resume(2);
diag("=== Second shot misses, no events");
diag("=== Third shot - action ended");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'RX78 hits with machine gun Dummy'
            }
        ]
    }
);
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 ended machine gun shots'
           }
        ]
    }
);

diag("Checking mechas stats");
is($world->armies->[0]->velocity, 10);
is($world->armies->[0]->position->x, 600);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->gauge, 0);
is($world->armies->[1]->life, 960);






diag("MongoDB cleanup");
$db->drop();



done_testing();

sub resume
{
    my $events = shift;
    if($world->armies->[0]->waiting)
    {
        diag("Resuming RX78 action");
        $world->armies->[0]->waiting(0);
        $world->add_command('RX78', { command => 'FLY TO WAYPOINT', params => 'WP-center', secondarycommand => 'machinegun', secondaryparams => 'Dummy', velocity => 10});
    }
    if($world->armies->[1]->waiting)
    {
        diag("Resuming Dummy action");
        $world->armies->[1]->waiting(0);
        $world->add_command('Dummy', {command => 'WAITING'});
    }
    is($world->action(), $events);
    $world->save;
}

