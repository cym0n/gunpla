use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;


diag("Reaching parallel waypoints");
my @dice;
for(my $i = 0; $i < 1000000; $i++) { push @dice, 1 }; 
my $world = Gunpla::Test::test_bootstrap('t016.csv', \@dice);
my $starting_point = { 'Guncannon'    => { command =>'guard', params => '20000' },
                       'Psychogundam' => { command =>'guard', params => '20000' } };
my $race           = { 'Guncannon'    => { command =>'flywp', params => 'WP-paris',     velocity => 6 },
                       'Psychogundam' => { command =>'flywp', params => 'WP-rome',      velocity => 6 } };
my $race2          = { 'Guncannon'    => { command =>'flywp', params => 'WP-marseille', velocity => 6 } };

is(Gunpla::Test::emulate_commands($world, $starting_point), 2, "Mechas start on guard");
ok($world->armies->[0]->is_status('stuck'), "Guncannon stuck after guard");
ok($world->armies->[1]->is_status('stuck'), "Psychogundam stuck after guard");
diag("Injecting inertia in Psychogundam");
$world->armies->[1]->inertia(50000);
is(Gunpla::Test::emulate_commands($world, $race), 1, "Guncannon should easily win the race");
is_deeply($world->get_events('Guncannon'), [ 'Guncannon reached destination: waypoint paris' ], "Guncannon won");
is($world->armies->[1]->position->y, 1667, "Checking Psychogundam position");
is($world->armies->[0]->position->y, 10000, "Checking Guncannon position");
diag("Injecting inertia in Guncannon");
$world->armies->[0]->inertia(200000);
is(Gunpla::Test::emulate_commands($world, $race2), 1, "Psychogundam reaches the WP, Guncannon is drifting");
is_deeply($world->get_events('Psychogundam'), [ 'Psychogundam reached destination: waypoint rome' ], "Psychogundam arrives");
is($world->armies->[1]->position->y, 10000, "Checking Psychogundam position");
is($world->armies->[0]->position->y, 18333, "Checking Guncannon position, drifted");
is($world->armies->[0]->position->z, 0, "Checking Guncannon position");

Gunpla::Test::clean_db('autotest', 1);

done_testing();
