use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

#THE STORY: Wing-1 tries to overcome the patrolling unit with the support of Wing-2, standing back and shooting with the rifle

my @dice = (1);
my $world = Gunpla::Test::test_bootstrap('arena-2.csv', \@dice, undef, 'stories.yaml');
$world->log_tracing([ 'Wing-1', 'Wing-2', 'Leo-3', 'Leo-4']);
my $wing1_index = 4;
my $wing2_index = 5;
my $adversary_index = 2;
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing-1' => { command =>'flywp', params => 'WP-blue', velocity => 4 },
      'Wing-2' => { command =>'flywp', params => 'WP-blue', velocity => 4 }, }
), 2, 'Wings fly together to destination');
is_deeply($world->get_events("Wing-1"), ["Wing-1 sighted Leo-3"], 'Wing-1 sights Leo-3');
is_deeply($world->get_events("Wing-2"), ["Wing-2 sighted Leo-3"], 'Wing-2 sights Leo-3');
position_test(-8703, -8703, -3704); 
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing-1' => { command =>'rifle', params => 'MEC-Leo-3' },
      'Wing-2' => { command =>'rifle', params => 'MEC-Leo-3' }, }
), 4, "Both Wings decide to use the rifle on leo-3");
is_deeply($world->get_events("Wing-1"), ["Wing-1 hits with rifle Leo-3"], "Wing-1 shoots");
is_deeply($world->get_events("Wing-2"), ["Wing-2 hits with rifle Leo-3"], "Wing-2 shoots");
position_test(-8703, -8703, -5578); #[d:2500] RIFLE GAUGE 15000, Leo-3 at velocity 6 fly 1500
my $wing_charge =  { 'Wing-1' => { command =>'flymec', params => 'MEC-Leo-3', secondarycommand => 'boost', velocity => 6 }};
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing-1' => { command =>'flymec', params => 'MEC-Leo-3', secondarycommand => 'boost', velocity => 6 },
      'Wing-2' => { command =>'rifle', params => 'MEC-Leo-3' }, }
), 2, "While Wing-1 charges on Leo-3, Wing-2 keeps shooting from distance. Wing-2 gets Leo-3 bullets");
is_deeply($world->get_events('Wing-1'), ["Leo-3 hits with machine gun Wing-1"], "Leo-3 hits with the machine gun");
is(Gunpla::Test::emulate_commands($world, $wing_charge), 2, "Wing-1 goes on with the charge");
is_deeply($world->get_events('Wing-1'), ["Leo-3 hits with machine gun Wing-1"], "Leo-3 hits with the machine gun");
is(Gunpla::Test::emulate_commands($world, $wing_charge), 2, "Wing-1 goes on with the charge");
is_deeply($world->get_events('Wing-1'), ["Wing-1 reached the nearby of mecha Leo-3"], "Wing-1 reached the nearby of mecha Leo-3");
is_deeply($world->get_events('Leo-3'), ["Leo-3 reached the nearby of mecha Wing-1"], "Leo-3 reached the nearby of mecha Wing");
position_test(-7157, -8703, -6158); #[d:1000]
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing-1' => { command =>'sword', params => 'MEC-Leo-3' }}
), 4, "Leo-3 uses sword too, blades clash");



Gunpla::Test::clean_db('autotest', 1);
done_testing();

sub position_test
{
    my $wing1_position = shift;
    my $wing2_position = shift;
    my $adversary_position = shift;
    my $distance1 = $wing1_position - $adversary_position;
    my $distance2 = $wing2_position - $adversary_position;
    $distance1 = $distance1 * -1 if $distance1 < 0;
    $distance2 = $distance2 * -1 if $distance2 < 0;
    is($world->armies->[$wing1_index]->position->x, $wing1_position, "Position of Wing-1 is $wing1_position");
    is($world->armies->[$wing2_index]->position->x, $wing2_position, "Position of Wing-2 is $wing2_position");
    is($world->armies->[$adversary_index]->position->x, $adversary_position, "Position of " . $world->armies->[$adversary_index]->name . " is $adversary_position");
    diag("Expected distance between " . $world->armies->[$adversary_index]->name . " and Wing-1: $distance1");
    diag("Expected distance between " . $world->armies->[$adversary_index]->name . " and Wing-2: $distance2");
}

