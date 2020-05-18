use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t108.csv');
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("Visible to RX78 (comprehend hostile mecha)");
$t->get_ok('/game/targets?game=autotest&mecha=RX78&filter=visible')
    ->status_is(200)
    ->json_is(
        {
          'targets' => 
                    [
                        {
                           'world_id' => 'AST-0',
                           'map_type' => 'AST',
                           'x' => '49000',
                           'id' => 0,
                           'z' => '10000',
                           'y' => '9000',
                           'distance' => 17379,
                           'label' => 'asteroid 0 (49000, 9000, 10000) d:17379'
                         },
                        {
                           'y' => 0,
                           'distance' => 120000,
                           'label' => 'mecha Hyakushiki (-60000, 0, 0) d:120000',
                           'id' => 'Hyakushiki',
                           'z' => 0,
                           'x' => -60000,
                           'world_id' => 'MEC-Hyakushiki',
                           'map_type' => 'MEC'
                        },
                        
                         {
                           'x' => '60000',
                           'map_type' => 'WP',
                           'world_id' => 'WP-blue',
                           'label' => 'waypoint blue (60000, 0, 0)',
                           'y' => '0',
                           'distance' => 0,
                           'z' => '0',
                           'id' => 'blue'
                         },
                         {
                           'x' => '0',
                           'map_type' => 'WP',
                           'world_id' => 'WP-center',
                           'label' => 'waypoint center (0, 0, 0) d:60000',
                           'y' => '0',
                           'distance' => 60000,
                           'z' => '0',
                           'id' => 'center'
                         },
                         {
                           'world_id' => 'WP-red',
                           'map_type' => 'WP',
                           'x' => '-60000',
                           'id' => 'red',
                           'z' => '0',
                           'y' => '0',
                           'distance' => 120000,
                           'label' => 'waypoint red (-60000, 0, 0) d:120000'
                         },
                         
                       ]

        });
Gunpla::Test::dump_api($t);
diag("Visible to Hyakushiki (no mecha)");
$t->get_ok('/game/targets?game=autotest&mecha=Hyakushiki&filter=visible')
    ->status_is(200)
    ->json_is(
        {
          'targets' => 
                    [
                         {
                           'world_id' => 'AST-0',
                           'map_type' => 'AST',
                           'x' => '49000',
                           'id' => 0,
                           'z' => '10000',
                           'y' => '9000',
                           'distance' => 109828,
                           'label' => 'asteroid 0 (49000, 9000, 10000) d:109828'
                         },
                         {
                           'x' => '60000',
                           'map_type' => 'WP',
                           'world_id' => 'WP-blue',
                           'label' => 'waypoint blue (60000, 0, 0) d:120000',
                           'y' => '0',
                           'distance' => 120000,
                           'z' => '0',
                           'id' => 'blue'
                         },
                         {
                           'x' => '0',
                           'map_type' => 'WP',
                           'world_id' => 'WP-center',
                           'label' => 'waypoint center (0, 0, 0) d:60000',
                           'y' => '0',
                           'distance' => 60000,
                           'z' => '0',
                           'id' => 'center'
                         },
                         {
                           'world_id' => 'WP-red',
                           'map_type' => 'WP',
                           'x' => '-60000',
                           'id' => 'red',
                           'z' => '0',
                           'y' => '0',
                           'distance' => 0,
                           'label' => 'waypoint red (-60000, 0, 0)'
                         }
                       ]

        });

Gunpla::Test::clean_db('autotest', 1);

done_testing();
