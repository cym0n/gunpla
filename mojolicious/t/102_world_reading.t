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

diag("Mechas read API");
$t->get_ok('/game/mechas?game=autotest')->status_is(200)->json_has('/mechas');

diag("Waypoints read API");
$t->get_ok('/game/waypoints?game=autotest')->status_is(200)->json_has('/waypoints');
open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);

diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();
