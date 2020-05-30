use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Gunpla::Position;
use Gunpla::Test;
use Gunpla::World;

my $world = Gunpla::Test::test_bootstrap('duel.csv');

is(Gunpla::Test::emulate_commands($world,
                                  { 'RX78' =>  { command => 'flywp', params => 'WP-center', velocity => 6 },
                                    'Hyakushiki' => {command => 'flywp', params => 'WP-center', velocity => 2} }),
1, "Mechas moving toward center until sighting event");

diag("Checking game status after sighting event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 10000);
is($world->armies->[0]->waiting, 1);
is($world->armies->[0]->cmd_index, 1);
is($world->armies->[0]->position->x, 68758);
is($world->armies->[1]->waiting, 0);
is($world->armies->[1]->cmd_index, 0);
is($world->armies->[1]->position->x, -71240);
is_deeply($world->get_events('RX78'), [ 'RX78 sighted Hyakushiki' ], "Checking event generation");

is(Gunpla::Test::emulate_commands($world,
                                  { 'RX78' =>  { command => 'flywp', params => 'WP-blue', velocity => 6, secondarycommand => 'machinegun', secondaryparams => 'MEC-Hyakushiki' } }),
2, "RX78 flying away from Hyakushiki to put it out of sight");
is_deeply($world->get_events('RX78'), [ 'RX78 reached destination: waypoint blue' ], "RX78 reaches waypoint, Hyakushiki out of sight doesn't bother him");

diag("Checking game status after the event");
is($world->sighting_matrix->{'RX78'}->{'Hyakushiki'}, 0, "RX78 Sighting matrix");
is($world->armies->[0]->waiting, 1, "RX79 Waiting");
is($world->armies->[0]->cmd_index, 2, "RX78 CMD index");
is($world->armies->[0]->position->x, 75000, "RX78 X position");
is($world->armies->[0]->attack, undef, "No machinegun");
is($world->armies->[1]->waiting, 0, "Hyakushiki Waiting");
is($world->armies->[1]->cmd_index, 0, "Hyakushiki CMD index");
is($world->armies->[1]->position->x, -67484, "Hyakushiki X position");


Gunpla::Test::clean_db('autotest', 1);
done_testing();

