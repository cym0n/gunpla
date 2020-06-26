use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

#THE STORY: Wing approaches the surveillance perimeter and encounter Leo-3. Leo-3 fly toward him with machingun. Wing first shoots with the RIFLE then turn on the BOOST to short the distance with the enemy and slash with the blade. Having the boost as bonus he wins the sword fight. One more hit finishes Leo-3
#    Inertia doesn't really affect Leo-3 because the original command: fly to WP-barcelona keeps him on track

my @dice = (15, 10, 15, 15, 1, 20, 0, 20, 20);
my $world = Gunpla::Test::test_bootstrap('arena-1.csv', \@dice, undef, 'stories.yaml');
$world->log_tracing([ 'Wing', 'Leo-3']);
is(@{$world->armies}, 5, "Checking mechas created on init");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'flywp', params => 'WP-blue', velocity => 4 } }
), 1, 'The bots try to reach the edges of the "patrolling diamond" while the Wing heads for blue waypoint');
is_deeply($world->get_events("Wing"), ["Wing sighted Leo-3"], 'Wing, having wider sensor range, detects the bot assigned to the farest waypoint: barcelona');
my $wing_index = 4;
my $adversary_index = 2;
position_test(-8703, -3704); #[d:4999] sensor range for Wing
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'rifle', params => 'MEC-Leo-3' }}
), 2, "Wing decides to use the rifle on leo-3");
is_deeply($world->get_events("Wing"), ["Wing hits with rifle Leo-3"], "With the Wing standing still, Leo-3 comes to sight him and run to him, machinegun ready. In the meantime Wing's rifle hits");
position_test(-8703, -5578); #[d:2500] RIFLE GAUGE 15000, Leo-3 at velocity 6 fly 1500
my $wing_charge =  { 'Wing' => { command =>'flymec', params => 'MEC-Leo-3', secondarycommand => 'boost', velocity => 6 }};
is(Gunpla::Test::emulate_commands($world, $wing_charge), 2, "Wing charges with boost");
is_deeply($world->get_events('Wing'), ["Leo-3 hits with machine gun Wing"], "Leo-3 hits with the machine gun");
position_test(-7522, -6022); #[d:1500] enter machinegun range
is(Gunpla::Test::emulate_commands($world, $wing_charge), 2, "Wing charges with boost");
is_deeply($world->get_events('Wing'), ["Leo-3 hits with machine gun Wing"], "Leo-3 hits with the machine gun");
position_test(-7255, -6122); #[d:1100]
is(Gunpla::Test::emulate_commands($world, $wing_charge), 2, "Wing charges with boost while Leo-3 ends his machine gun attack");
is_deeply($world->get_events('Wing'), ["Wing reached the nearby of mecha Leo-3"], "Wing reached the nearby of mecha Leo-3");
is_deeply($world->get_events('Leo-3'), ["Leo-3 reached the nearby of mecha Wing"], "Leo-3 reached the nearby of mecha Wing");
position_test(-7157, -6158); #[d:1000]
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'sword', params => 'MEC-Leo-3' }}
), 2, "Leo-3 uses sword too, blades clash");
is_deeply($world->get_events('Wing'), ["Wing slash with sword mecha Leo-3"], "Wing slash with sword mecha Leo-3");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'sword', params => 'MEC-Leo-3' }}
), 2, "Second sword hit");
is($world->cemetery->[0]->name, "Leo-3", "Leo-3 is dead");
is($world->armies->[3]->life, 800, "Wing life");
is($world->armies->[3]->energy, 34477, "Wing Energy");
$world->log_tracing([ 'Wing', 'Leo-4' ]);
$adversary_index = 2;
$wing_index = 3;
position_test(-6861, 1072); #[d:~5400]
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'flywp', params => 'WP-blue', velocity => 4 } }
), 1, 'Wing heading his target after Leo-3 defeat');
is_deeply($world->get_events('Wing'), ["Wing sighted Leo-4"], "Leo-4, called by Leo-3, joins the fight");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'flywp', params => 'WP-blue', velocity => 4 } }
), 2, 'Wing ignores Leo-4');

Gunpla::Test::clean_db('autotest', 1);
done_testing();

sub position_test
{
    my $wing_position = shift;
    my $adversary_position = shift;
    my $distance = $wing_position - $adversary_position;
    $distance = $distance * -1 if $distance < 0;
    is($world->armies->[$adversary_index]->position->x, $adversary_position, "Position of " . $world->armies->[$adversary_index]->name . " is $adversary_position");
    is($world->armies->[$wing_index]->position->x, $wing_position, "Position of Wing is $wing_position");
    diag("Expected distance: $distance");
}
