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
my $commands = { 'Guncannon' => { command =>'flywp', params => 'WP-paris', velocity => 4, secondarycommand => 'boost'},
                 'Psychogundam' => { command =>'flywp', params => 'WP-rome', velocity => 6}};
$world->armies->[0]->set_destination($world->waypoints->{'paris'});
$world->armies->[0]->velocity(5);
$world->armies->[1]->set_destination($world->waypoints->{'rome'});
$world->armies->[1]->velocity(6);
#$world->armies->[1]->energy(10000);
is(Gunpla::Test::emulate_commands($world, $commands), 1);
diag("Guncannon go further");
is_deeply($world->get_events('Guncannon'), [ 'Guncannon exhausted boost' ]);
is($world->armies->[0]->position->y, 16666, "Guncannon Y position");
is($world->armies->[1]->position->y, 8333, "Psychogundam Y position");
is($world->armies->[0]->energy, 500000, "Guncannon energy");
is($world->armies->[1]->energy, 650000, "Psychogundam energy");


Gunpla::Test::clean_db('autotest', 1);
done_testing();
