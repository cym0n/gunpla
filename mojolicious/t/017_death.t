use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t017.csv', [20]);
$world->armies->[0]->life(10);
$world->armies->[1]->position->x(300000);
$world->sighting_matrix->reset($world->armies);

ok($world->sighting_matrix->see_faction('eagle', 'Diver'), "Eagle faction sees Diver because Gelgoog is near");
is(@{$world->armies}, 3, "Scenario starts with 3 mechas");
is(@{$world->cemetery}, 0, "Cemetery is empty");
my $commands = { 'Diver' => { command => 'rifle', params => 'MEC-Gelgoog'} };
is(Gunpla::Test::emulate_commands($world, $commands), 2, "RX78 shoot to a very weak dummy with a rifle");
ok(! $world->sighting_matrix->see_faction('eagle', 'Diver'), "Eagle faction can't see Diver anymore");
is(@{$world->armies}, 2, "2 mechas left");
is(@{$world->cemetery}, 1, "Gelgoog in the cemetery");

Gunpla::Test::clean_db('autotest', 1);
done_testing();
