use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;


diag("Reaching parallel waypoints");
my $world = Gunpla::Test::test_bootstrap('race.csv');
my $commands = { 'Guncannon' => { command =>'flywp', params => 'WP-paris', velocity => 6},
                 'Psychogundam' => { command =>'flywp', params => 'WP-rome', velocity => 5}};
$world->armies->[0]->set_destination($world->waypoints->{'paris'});
$world->armies->[0]->velocity(5);
$world->armies->[1]->set_destination($world->waypoints->{'rome'});
$world->armies->[1]->velocity(5);
$world->armies->[1]->energy(10000);
is(Gunpla::Test::emulate_commands($world, $commands), 1);
diag("Guncannon reached destination as first. Energy consumed, max velocity");
is_deeply($world->get_events('Guncannon'), [ 'Guncannon reached destination: waypoint paris' ]);
is($world->armies->[0]->energy, 460084);
is($world->armies->[0]->velocity, 6);
diag("Psychogundam reached destination as second. Energy not consumed, velocity 5");
is(Gunpla::Test::emulate_commands($world, { 'Guncannon' => { command => 'wait' }}), 1);
is_deeply($world->get_events('Psychogundam'), [ 'Psychogundam reached destination: waypoint rome' ]);
is($world->armies->[1]->energy, 10000);
is($world->armies->[1]->velocity, 5);
diag("Psychogundam tries to do another trip max energy exhausting small reserve");
is(Gunpla::Test::emulate_commands($world, { 'Psychogundam' => { command =>'flywp', params => 'WP-blue', velocity => 6}}), 1);
is_deeply($world->get_events('Psychogundam'), [ 'Psychogundam exhausted energy' ]);
is($world->armies->[1]->energy, 0);
is($world->armies->[1]->velocity, 4);
diag("Psychogundam reach destination and velocity 4, recharging");
is(Gunpla::Test::emulate_commands($world, { 'Psychogundam' => { command =>'flywp', params => 'WP-blue', velocity => 4}}), 1);
is($world->armies->[1]->energy, 66332);
is($world->armies->[1]->velocity, 4);

Gunpla::Test::clean_db('autotest', 1);
done_testing();
