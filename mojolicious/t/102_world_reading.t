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

diag("Mechas read API - all");
$t->get_ok('/game/mechas?game=autotest')->status_is(200)->json_has('/mechas');
diag("Mechas read API - single");
$t->get_ok('/game/mechas?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        mecha => {
            name => 'Diver',
            faction => 'wolf',
            position => { x => 500000, y => 0, z => 0 },
            waiting => 1
        }
    }
);

diag("Waypoints read API");
$t->get_ok('/game/waypoints?game=autotest')->status_is(200)->json_has('/waypoints');
diag("Waypoints read API - single");
$t->get_ok('/game/waypoints?game=autotest&waypoint=center')->status_is(200)->json_is(
    {
        waypoint => {
            name => 'center',
            x => 0,
            y => 0,
            z => 0
        }
    }
);
open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);

diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();
