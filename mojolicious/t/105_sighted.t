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
$world->init_test('duel');
$world->add_mecha("Gelgoog", "eagle");
$world->get_mecha_by_name("Diver")->position(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->get_mecha_by_name("Zaku")->position(Gunpla::Position->new(x => 50000, y => 0, z => 0));
$world->get_mecha_by_name("Gelgoog")->position(Gunpla::Position->new(x => 120000, y => 0, z => 0));
$world->calculate_sighting_matrix("Diver");
$world->calculate_sighting_matrix("Zaku");
$world->calculate_sighting_matrix("Gelgoog");
$world->save();

my $t = Test::Mojo->new('GunplaServer');
diag("What Diver sighted");
$t->get_ok('/game/sighted?game=autotest&mecha=Diver')
    ->status_is(200)
    ->json_is({
          'mechas' => [
                        {
                          'waiting' => 1,
                          'faction' => 'eagle',
                          'name' => 'Zaku',
                          'life' => 1000,
                          'position' => {
                                          'z' => 0,
                                          'y' => 0,
                                          'x' => 50000
                                        }
                        },
                        {
                          'position' => {
                                          'y' => 0,
                                          'z' => 0,
                                          'x' => 120000
                                        },
                          'name' => 'Gelgoog',
                          'faction' => 'eagle',
                          'life' => 1000,
                          'waiting' => 1
                        }
                      ]
           });
$t->get_ok('/game/sighted?game=autotest&mecha=Zaku')
    ->status_is(200)
    ->json_is({
          'mechas' => [
                        {
                          'waiting' => 1,
                          'faction' => 'wolf',
                          'name' => 'Diver',
                          'life' => 1000,
                          'position' => {
                                          'z' => 0,
                                          'y' => 0,
                                          'x' => 0
                                        }
                        },
                      ]
           });

open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);

diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();
