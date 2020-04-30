use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv', [20, 3, 20]);

my $commands = { 'RX78' => { command => 'FLY TO WAYPOINT', params => 'WP-center', secondarycommand => 'machinegun', secondaryparams => 'MEC-Dummy', velocity => 10},
                 'Dummy' => { command => 'WAITING' } };

is(Gunpla::Test::emulate_commands($world, $commands), 2);

diag("=== First shot");
diag("Checking event generation");
is_deeply($world->get_events('Dummy'), [  'RX78 hits with machine gun Dummy' ]);

diag("Checking mechas stats");
is($world->armies->[0]->position->x, 1000);
is($world->armies->[0]->velocity, 10);
is($world->armies->[0]->attack_limit, 2);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[1]->life, 980);

is(Gunpla::Test::emulate_commands($world, $commands), 5);

diag("=== Second shot misses, no events");
diag("=== Third shot - action ended");
diag("Checking event generation");
is_deeply($world->get_events('Dummy'), [  'RX78 hits with machine gun Dummy' ]);
is_deeply($world->get_events('RX78'), [  'RX78 ended machine gun shots' ]);

diag("Checking mechas stats");
is($world->armies->[0]->velocity, 10);
is($world->armies->[0]->position->x, 600);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[1]->life, 960);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
