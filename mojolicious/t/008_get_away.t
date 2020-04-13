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

$world->armies->[0]->position->x(200000);
$world->armies->[0]->waiting(0);
$world->add_command('Diver', 'GET AWAY', 'WP-center');
$world->armies->[1]->waiting(0);
$world->add_command('Dummy', 'WAITING');
is($world->action(), 1);
$world->save;
diag("Diver got away");
$t->get_ok('/game/event?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Diver',
                message => 'Diver reached destination: void space'
            }
        ]
    }
);
diag("Check Diver position");
is($world->armies->[0]->position->x, 230000);

open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);
diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();

