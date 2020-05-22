use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv', [20, 3, 20]);

my $commands = { 'RX78' => { command => 'flywp', params => 'WP-center', secondarycommand => 'machinegun', secondaryparams => 'MEC-Dummy', velocity => 10} };

#First shot: blocking just for Dummy, but it's an automated mecha -> events reset
#Events after it:
#  RX78:  RX78 missed Dummy with machine gun (not blocking)
#  Dummy: RX78 missed Dummy with machine gun (not blocking)
#  RX78:  RX78 hits with machine gun Dummy   (not blocking)
#  Dummy: RX78 hits with machine gun Dummy   (blocking)
#  RX78:  RX78 ended machine gun shots       (blocking)
diag("RX78 fires machinegun on Dummy");
is(Gunpla::Test::emulate_commands($world, $commands), 5);
is_deeply($world->get_events('RX78'), [  'RX78 ended machine gun shots' ]);
is_deeply($world->get_events('Dummy'), [  'RX78 hits with machine gun Dummy' ]);
diag("Checking mechas stats");
is($world->armies->[0]->velocity, 10);
is($world->armies->[0]->position->x, 600);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[1]->life, 960);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
