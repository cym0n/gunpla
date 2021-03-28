use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

# Same of 013_boost test, velocity of Guncannon is now 6, to underline differences

diag("Trying to reach velocity to boost");
my $world = Gunpla::Test::test_bootstrap('t022.csv');
my $commands = { 'DiverB' => { command =>'flywp', params => 'WP-center', velocity => 4, secondarycommand => 'boost'}};
$world->armies->[0]->set_destination($world->waypoints->{'center'});
$world->armies->[0]->velocity(3);
is(Gunpla::Test::emulate_commands($world, $commands), 2);
is_deeply($world->get_events('DiverB'), [ 'DiverB has no energy for boost' ]);
is($world->armies->[0]->get_velocity, 4, "DiverB velocity"); 
is($world->armies->[0]->position->x, 68889, "DiverB position"); 
my $commands2 = { 'DiverB' => { command =>'flywp', params => 'WP-center', velocity => 6}};
is(Gunpla::Test::emulate_commands($world, $commands2), 1);
is_deeply($world->get_events('DiverB'), [ 'DiverB reached destination: waypoint center' ]);
is($world->armies->[0]->get_velocity, 6, "DiverB velocity"); 
is($world->armies->[0]->position->x, 0, "DiverB position"); 
my $commands3 = { 'DiverB' => { command =>'flywp', params => 'WP-proxima', velocity => 4, secondarycommand => 'boost'}};
is(Gunpla::Test::emulate_commands($world, $commands3), 2);
is_deeply($world->get_events('DiverB'), [ 'DiverB reached destination: waypoint proxima' ]);
is($world->armies->[0]->get_velocity, 8, "DiverB velocity (boost)"); 
is($world->armies->[0]->position->x, -5000, "DiverB position"); 
Gunpla::Test::clean_db('autotest', 1);
done_testing();
