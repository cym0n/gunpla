use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Gunpla::Position;

diag("Main library load");
require_ok('Gunpla::World');

my $world = Gunpla::World->new(name => 'autotest');
$world->init_test('duel');

diag("Simulation of order received");
$world->armies->[0]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[0]->movement_target({ type => 'waypoint', name => 'center', class => 'fixed'});
$world->armies->[1]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[1]->movement_target({ type => 'waypoint', name => 'center', class => 'fixed'});
$world->armies->[0]->waiting(0);
$world->armies->[1]->waiting(0);

#100 clocks to accelerate to velocity 1. At velocity 1 you need 11 clocks for a step
$world->action(156);

diag("Position of mechas after 10 steps of movement");
is($world->armies->[0]->position->x, 74995);
is($world->armies->[1]->position->x, -74995);

done_testing();

