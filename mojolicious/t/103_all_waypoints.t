use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init();
$world->save();

my $t = Test::Mojo->new('GunplaServer');

$t->get_ok('/game/waypoints?game=autotest')->status_is(200)->json_is(
{ 'waypoints' => [
    {
        'type' => 'waypoint',
        '_id' => '5e850d147191313967fdbee3',
        'spawn_point' => 'wolf',
        'position' => { 'y' => 0, 'z' => 0, 'x' => 500000 },
        'name' => 'blue'
    },
    {
        'type' => 'waypoint',
        '_id' => '5e850d147191313967fdbee3',
        'spawn_point' => 'eagle',
        'position' => { 'y' => 0, 'z' => 0, 'x' => -500000 },
        'name' => 'red'
    },
    {
        'type' => 'waypoint',
        '_id' => '5e850d147191313967fdbee3',
        'spawn_point' => '',
        'position' => { 'y' => 0, 'z' => 0, 'x' => 0 },
        'name' => 'center'
    }
]
});
open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);

#diag("Drop gunpla_autotest db on local mongodb for final cleanup");
#$db = $mongo->get_database('gunpla_autotest');
#$db->drop();


done_testing();
