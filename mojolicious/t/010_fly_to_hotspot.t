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
my $world = Gunpla::World->new(name => 'autotest');
$world->init_test('dummy');

my $t = Test::Mojo->new('GunplaServer');

$world->armies->[0]->waiting(0);
$world->add_command('RX78', { command =>'FLY TO HOTSPOT', params => 'AST-0', velocity => 10});
$world->armies->[1]->waiting(0);
$world->add_command('Dummy', {command => 'WAITING'});
is($world->action(), 1);
$world->save;
diag("RX78 is nearby the asteroid");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 reached the nearby of asteroid 0'
            }
        ]
    }
);
diag("Check RX78 position");
is($world->armies->[0]->position->x, 29423);
is($world->armies->[0]->position->y, 9423);
is($world->armies->[0]->position->z, 9424);

$world->armies->[0]->waiting(0);
$world->add_command('RX78', { command =>'LAND', params => 'AST-0'});
is($world->action(), 1);
$world->save;
diag("RX78 landed on the asteroid");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 landed on asteroid 0'
            }
        ]
    }
);
is($world->armies->[0]->position->x, 30000);
is($world->armies->[0]->position->y, 10000);
is($world->armies->[0]->position->z, 10000);
is($world->armies->[0]->velocity, 0);
is($world->armies->[0]->is_status('landed'), 1);

open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);
diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();

