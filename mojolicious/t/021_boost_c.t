use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

# Same of 013_boost test, velocity of Guncannon is now 6, to underline differences

diag("Reaching parallel waypoints");
my $world = Gunpla::Test::test_bootstrap('t021.csv');
my $commands = { 'Wing' => { command =>'flywp', params => 'WP-scorpio', velocity => 4, secondarycommand => 'boost'}};
my $commands2 = { 'Wing' => { command =>'flywp', params => 'WP-aries', velocity => 4 }};
my $commands3 = { 'Wing' => { command =>'flywp', params => 'WP-virgo', velocity => 4, secondarycommand => 'boost'}};
is(Gunpla::Test::emulate_commands($world, $commands), 1);
is_deeply($world->get_events('Wing'), [ 'Wing reached destination: waypoint scorpio' ]);
is($world->armies->[0]->energy, 16, "Wing energy"); 
is($world->armies->[0]->get_velocity, 9, "Wing velocity (boosted)"); 
is($world->armies->[0]->action, 'BOOST', "Boost active"); 
is($world->armies->[0]->get_gauge_level('boost'), 30000, "Boost level"); 
is(Gunpla::Test::emulate_commands($world, $commands2), 1);
is_deeply($world->get_events('Wing'), [ 'Wing reached destination: waypoint aries' ]);
is($world->armies->[0]->energy, 16, "Wing energy"); 
is($world->armies->[0]->get_velocity, 9, "Wing velocity (boosted)"); 
is($world->armies->[0]->action, 'BOOST', "Boost active"); 
is($world->armies->[0]->get_gauge_level('boost'), 24000, "Boost level"); 
is(Gunpla::Test::emulate_commands($world, $commands3), 1);
is_deeply($world->get_events('Wing'), [ 'Wing reached destination: waypoint virgo' ]);
is($world->armies->[0]->energy, 16, "Wing energy"); 
is($world->armies->[0]->get_velocity, 9, "Wing velocity (boosted)"); 
is($world->armies->[0]->action, 'BOOST', "Boost active"); 
is($world->armies->[0]->get_gauge_level('boost'), 18000, "Boost level"); 

Gunpla::Test::clean_db('autotest', 1);
done_testing();
