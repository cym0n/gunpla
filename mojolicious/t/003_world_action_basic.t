use strict;
use v5.10;
use lib 'lib';

use Test::More;
use Gunpla::Position;

diag("Main library load");
require_ok('Gunpla::World');

my $world = Gunpla::World->new();
$world->init();

diag("Simulation of order received");
$world->armies->[0]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[1]->destination(Gunpla::Position->new(x => 0, y => 0, z => 0));
$world->armies->[0]->waiting(0);
$world->armies->[1]->waiting(0);
$world->action(10);

diag("Position of mechas after 10 steps of movement");
is($world->armies->[0]->position->x, 499990);
is($world->armies->[1]->position->x, -499990);

done_testing();

