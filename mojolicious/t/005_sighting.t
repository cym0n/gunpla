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
1);

diag("Checking game status after the event");
is($world->sighting_matrix->matrix->{'RX78'}->{'Hyakushiki'}, 10000);
is($world->armies->[0]->waiting, 1);
is($world->armies->[0]->cmd_index, 1);
is($world->armies->[0]->position->x, 68758);
is($world->armies->[1]->waiting, 0);
is($world->armies->[1]->cmd_index, 0);
is($world->armies->[1]->position->x, -71240);
is_deeply($world->get_events('RX78'), [ 'RX78 sighted Hyakushiki' ], "Checking event generation");

$world->armies->[1]->waiting(1);

is(Gunpla::Test::emulate_commands($world,
                                  { 'RX78' =>  { command => 'flymec', params => 'MEC-Hyakushiki', velocity => 1 },
                                    'Hyakushiki' =>  { command => 'flywp', params => 'WP-red', velocity => 6 } 

}),
1, "Hyakushiki get away from RX78 that is chasing him issuing blocking event");
is_deeply($world->get_events('RX78'), [ 'contact lost: Hyakushiki' ], "Checking event generation");

diag("Checking game status after the event");
is($world->sighting_matrix->matrix->{'RX78'}->{'Hyakushiki'}, 0, "RX78 Sighting matrix");
is($world->armies->[0]->waiting, 1, "RX79 Waiting");
is($world->armies->[0]->cmd_index, 2, "RX78 CMD index");
is($world->armies->[0]->position->x, 67835, "RX78 X position");
is($world->armies->[1]->waiting, 0, "Hyakushiki Waiting");
is($world->armies->[1]->cmd_index, 0, "Hyakushiki CMD index");
is($world->armies->[1]->position->x, -72913, "Hyakushiki X position");


Gunpla::Test::clean_db('autotest', 1);
done_testing();

