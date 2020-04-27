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
my $t = Test::Mojo->new('GunplaServer');

diag("Proposed to RX78 ");
$t->get_ok('/game/hotspots?game=autotest&mecha=RX78')
    ->status_is(200)
    ->json_is(
        {
          'hotspots' => [
                          {
                            'y' => '10000',
                            'z' => '9000',
                            'id' => 0,
                            'x' => '50000',
                            'world_id' => 'AST-0',
                            'map_type' => 'asteroid',
                            'label' => 'asteroid (50000, 10000, 9000) d:28391',
                            'distance' => 28391,
                          },
                          {
                            'map_type' => 'asteroid',
                            'label' => 'asteroid (49000, 9000, 10000) d:29275',
                            'world_id' => 'AST-1',
                            'x' => '49000',
                            'y' => '9000',
                            'z' => '10000',
                            'id' => 1,
                            'distance' => 29275
                          }
                        ]
        });

diag("Proposed to Hyakushiki");
$t->get_ok('/game/hotspots?game=autotest&mecha=Hyakushiki')
    ->status_is(200)
    ->json_is({
          'hotspots' => [
                          {
                            'world_id' => 'AST-0',
                            'z' => '9000',
                            'y' => '10000',
                            'map_type' => 'asteroid',
                            'id' => 0,
                            'label' => 'asteroid (50000, 10000, 9000) d:125722',
                            'x' => '50000',
                            'distance' => 125722,
                          },
                          {
                            'x' => '49000',
                            'label' => 'asteroid (49000, 9000, 10000) d:124728',
                            'y' => '9000',
                            'map_type' => 'asteroid',
                            'id' => 1,
                            'world_id' => 'AST-1',
                            'z' => '10000',
                            'distance' => 124728,
                          }
                        ]
        });

diag("Proposed to RX78 for landing (none) ");
$t->get_ok('/game/hotspots?game=autotest&mecha=RX78&action=land')
    ->status_is(200)
    ->json_is(
        {
          'hotspots' => []
        });

diag("Moving RX78 near an asteroid");
$world->armies->[0]->position->x(69500);
$world->armies->[0]->position->y(10000);
$world->armies->[0]->position->z(9000);
$world->save;

diag("Proposed to RX78 for landing (one)");
$t->get_ok('/game/hotspots?game=autotest&mecha=RX78&action=land')
    ->status_is(200)
    ->json_is({
          'hotspots' => [
            {
              'id' => 0,
              'world_id' => 'AST-0',
              'label' => 'asteroid (50000, 10000, 9000) d:19500',
              'map_type' => 'asteroid',
              'x' => '50000',
              'y' => '10000',
              'z' => '9000',
              'distance' => 19500,
            }]
    });
Gunpla::Test::dump_api($t);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
