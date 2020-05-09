use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

diag("Reaching parallel waypoints");
my $world = Gunpla::Test::test_bootstrap('t012.csv');
my $commands = { 'Diver' => { command =>'FLY TO WAYPOINT', params => 'WP-paris', velocity => 6},
                 'Zaku' => { command =>'FLY TO WAYPOINT', params => 'WP-rome', velocity => 4}};
$world->armies->[0]->velocity(4);
$world->armies->[1]->velocity(4);
is(Gunpla::Test::emulate_commands($world, $commands), 1);
diag("Diver reached destination as first. Energy consumed, max velocity");
is_deeply($world->get_events('Diver'), [ 'Diver reached destination: waypoint paris' ]);
is($world->armies->[0]->energy, 687382);
is($world->armies->[0]->velocity, 6);
diag("Zaku reached destination as second. Energy not consumed, velocity 4");
is(Gunpla::Test::emulate_commands($world, { 'Diver' => { command => 'WAITING' }}), 1);
is_deeply($world->get_events('Zaku'), [ 'Zaku reached destination: waypoint rome' ]);
is($world->armies->[1]->energy, 700000);
is($world->armies->[1]->velocity, 4);

Gunpla::Test::clean_db('autotest', 1);
done_testing();
