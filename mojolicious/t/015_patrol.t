use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('arena-0.csv', [ 15, 10, 15, 15, 15 ]);
is(@{$world->armies}, 5, "Checking mechas created on init");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'flywp', params => 'WP-blue', velocity => 4 }}
), 1, 'The bots try to reach the edges of the "patrolling diamond" while the Wing heads for blue waypoint');
is_deeply($world->get_events("Wing"), ["Wing sighted Leo-3"], 'Wing, having wider sensor range, detects the bot assigned to the farest waypoint: barcelona');
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'rifle', params => 'MEC-Leo-3' }}
), 2, "Wing decides to use the rifle on leo-3");
is_deeply($world->get_events("Wing"), ["Wing hits with rifle Leo-3"], "With the Wing standing still, Leo-3 comes to sight him and run to him, machinegun ready. In the meantime Wing's rifle hits");
is($world->armies->[2]->position->x, -1093, "Position of Leo-3 is -1093");
is($world->armies->[4]->position->x, -3592, "Position of Wing is -3592");
my $wing_charge =  { 'Wing' => { command =>'flymec', params => 'MEC-Leo-3', secondcommand => 'boost', velocity => 6 }};
is(Gunpla::Test::emulate_commands($world, $wing_charge, 2), "Wing charges with boost");
is_deeply($world->get_events('Wing'), ["Leo-3 hits with machine gun Wing"], "Leo-3 hits with the machine gun");
is(Gunpla::Test::emulate_commands($world, $wing_charge, 2), "Wing charges with boost");
is_deeply($world->get_events('Wing'), ["Leo-3 hits with machine gun Wing"], "Leo-3 hits with the machine gun");
is(Gunpla::Test::emulate_commands($world, $wing_charge, 2), "Wing charges with boost");
is_deeply($world->get_events('Wing'), ["Leo-3 hits with machine gun Wing"], "Leo-3 hits with the machine gun");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'sword', params => 'MEC-Leo-3' }}
), 2, "Leo-3 uses sword too, blades clash");

Gunpla::Test::clean_db('autotest', 1);
done_testing();
