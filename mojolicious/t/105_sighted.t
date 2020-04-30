use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('duel.csv');
$world->add_mecha("Gelgoog", "eagle");
$world->get_mecha_by_name("RX78")->position(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->get_mecha_by_name("Hyakushiki")->position(Gunpla::Position->new(x => 50000, y => 0, z => 0));
$world->get_mecha_by_name("Gelgoog")->position(Gunpla::Position->new(x => 120000, y => 0, z => 0));
$world->calculate_sighting_matrix("RX78");
$world->calculate_sighting_matrix("Hyakushiki");
$world->calculate_sighting_matrix("Gelgoog");
$world->save();
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("What RX78 sighted");
$t->get_ok('/game/sighted?game=autotest&mecha=RX78')
    ->status_is(200)
    ->json_is({
          'mechas' => [
                        {
                          'waiting' => 1,
                          'faction' => 'eagle',
                          'name' => 'Hyakushiki',
                          'label' => 'Hyakushiki',
                          'world_id' => 'MEC-Hyakushiki',
                          'map_type' => 'mecha',
                          'life' => 1000,
                          'velocity' => 0,
                          'max_velocity' => 10,
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
                          'label' => 'Gelgoog',
                          'world_id' => 'MEC-Gelgoog',
                          'map_type' => 'mecha',
                          'faction' => 'eagle',
                          'life' => 1000,
                          'velocity' => 0,
                          'max_velocity' => 6,
                          'waiting' => 1
                        }
                      ]
           });

diag("What Hyakushiki sighted");
$t->get_ok('/game/sighted?game=autotest&mecha=Hyakushiki')
    ->status_is(200)
    ->json_is({
          'mechas' => [
                        {
                          'waiting' => 1,
                          'faction' => 'wolf',
                          'name' => 'RX78',
                          'label' => 'RX78',
                          'world_id' => 'MEC-RX78',
                          'map_type' => 'mecha',
                          'life' => 1000,
                          'velocity' => 0,
                          'max_velocity' => 10,
                          'position' => {
                                          'z' => 0,
                                          'y' => 0,
                                          'x' => 0
                                        }
                        },
                      ]
           });
Gunpla::Test::dump_api($t);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
