use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('arena-0.csv');
diag("Checking mechas created on init");
is(@{$world->armies}, 5);
diag('The bots try to reach the edges of the "patrolling diamond" while the Wing heads for blue waypoint');
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'flywp', params => 'WP-blue', velocity => 4 }}
), 1);
diag('Wing, having wider sensor range, detects the bot assigned to the further waypoint: barcelona');
is_deeply($world->get_events("Wing"), ["Wing sighted Leo-3"]);
diag("Wing decides to use the rifle on Leo-3");
is(Gunpla::Test::emulate_commands($world, 
    { 'Wing' => { command =>'rifle', params => 'MEC-Leo-3' }}
), 1);
diag("With the Wing standing still, Leo-3 comes to sight him");
is_deeply($world->get_events("Leo-3"), ["Leo-3 sighted Wing"]);
Gunpla::Test::clean_db('autotest', 1);
done_testing();
