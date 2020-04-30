use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Gunpla::Position;
use Gunpla::Test;
use Gunpla::World;

my $world = Gunpla::Test::test_bootstrap('duel.csv');

is(Gunpla::Test::emulate_commands($world,
                                  { 'RX78' =>  { command => 'FLY TO WAYPOINT', params => 'WP-center', velocity => 6 },
                                    'Hyakushiki' => {command => 'FLY TO WAYPOINT', params => 'WP-center', velocity => 2} }),
1);

diag("Checking game status after the event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 10000);
is($world->armies->[0]->waiting, 1);
is($world->armies->[0]->cmd_index, 1);
is($world->armies->[0]->position->x, 68758);
is($world->armies->[1]->waiting, 0);
is($world->armies->[1]->cmd_index, 0);
is($world->armies->[1]->position->x, -71240);

diag("Checking event generation");
is_deeply($world->get_events('RX78'), [ 'RX78 sighted Hyakushiki' ]);

diag("Flying away from Hyakushiki");
is(Gunpla::Test::emulate_commands($world,
                                  { 'RX78' =>  { command => 'FLY TO WAYPOINT', params => 'WP-blue', velocity => 6 } }),
1);

diag("Checking game status after the event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 0, "RX78 Sighting matrix");
is($world->armies->[0]->waiting, 1, "RX79 Waiting");
is($world->armies->[0]->cmd_index, 2, "RX78 CMD index");
is($world->armies->[0]->position->x, 70444, "RX78 X position");
is($world->armies->[1]->waiting, 0, "Hyakushiki Waiting");
is($world->armies->[1]->cmd_index, 0, "Hyakushiki CMD index");
is($world->armies->[1]->position->x, -70217, "Hyakushiki X position");

diag("Checking event generation (using API)");
is_deeply($world->get_events('RX78'), [ 'RX78 lost contact with Hyakushiki' ]);

Gunpla::Test::clean_db('autotest', 1);
done_testing();

