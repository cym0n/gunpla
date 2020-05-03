use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t105.csv');
$world->get_mecha_by_name("Hyakushiki")->position(Gunpla::Position->new(x => 50000, y => 0, z => 0));
$world->calculate_sighting_matrix("RX78"); #Sensor range: 140000
$world->calculate_sighting_matrix("Hyakushiki"); #Sensor range: 80000
$world->calculate_sighting_matrix("Dom"); #Sensor range: 130000
$world->save();
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("What RX78 sighted");
$t->get_ok('/game/targets?game=autotest&mecha=RX78&filter=sighted-by-me')
    ->status_is(200)
    ->json_is(
        {
            'targets' => [
                {
                    'id' => 'Dom',
                    'world_id' => 'MEC-Dom',
                    'label' => 'mecha Dom (120000, 0, 0) d:120000',
                    'map_type' => 'mecha',
                    'x' => 120000,
                    'y' => 0,
                    'z' => 0,
                    'distance' => 120000,
                },
                {
                    'id' => 'Hyakushiki',
                    'world_id' => 'MEC-Hyakushiki',
                    'label' => 'mecha Hyakushiki (50000, 0, 0) d:50000',
                    'map_type' => 'mecha',
                    'x' => 50000,
                    'y' => 0,
                    'z' => 0,
                    'distance' => 50000,
                }
            ]
        });

diag("What Hyakushiki sighted");
$t->get_ok('/game/targets?game=autotest&mecha=Hyakushiki&filter=sighted-by-me')
    ->status_is(200)
    ->json_is({
          'targets' => [
                         {
                           'id' => 'RX78',
                           'world_id' => 'MEC-RX78',
                           'label' => 'mecha RX78 (0, 0, 0) d:50000',
                           'map_type' => 'mecha',
                           'x' => 0,
                           'z' => 0,
                           'y' => 0,
                           'distance' => 50000,
                         }
                       ]
        });
diag("What Dom sighted");
$t->get_ok('/game/targets?game=autotest&mecha=Dom&filter=sighted-by-me')
    ->status_is(200)
    ->json_is({
          'targets' => [
                       ]
        });
diag("What Dom sighted (by faction)");
$t->get_ok('/game/targets?game=autotest&mecha=Hyakushiki&filter=sighted-by-faction')
    ->status_is(200)
    ->json_is({
          'targets' => [
                         {
                           'id' => 'RX78',
                           'world_id' => 'MEC-RX78',
                           'label' => 'mecha RX78 (0, 0, 0) d:50000',
                           'map_type' => 'mecha',
                           'x' => 0,
                           'z' => 0,
                           'y' => 0,
                           'distance' => 50000,
                         }
                       ]
        });

Gunpla::Test::dump_api($t);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
