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

ok($world->sighting_matrix->see_faction('eagle', 'Diver-1'), "Eagle faction sees Diver because Gelgoog is near");
is(@{$world->armies}, 4, "Scenario starts with 3 mechas");
is(@{$world->cemetery}, 0, "Cemetery is empty");
my $commands = { 'Diver-1' => { command => 'rifle', params => 'MEC-Gelgoog'},
                 'Diver-2' => { command => 'guard', params => 100  } };
is(Gunpla::Test::emulate_commands($world, $commands), 1, "Diver-2 shifted of few steps to test attack target on enemy death");
is(Gunpla::Test::emulate_commands($world, { 'Diver-2' => { command => 'rifle', params => 'MEC-Gelgoog'} }), 4, "Diver-1 shoot to a very weak Gelgoog with a rifle. Diver-2 is aiming the same target");
is_deeply($world->get_events('Diver-1'), ["Diver-1 hits with rifle Gelgoog", "contact lost: Gelgoog"], "Diver-1 register the rifle host and loses contact with the target");
is_deeply($world->get_events('Diver-2'), ["contact lost: Gelgoog"], "Diver-2 loses contact with the target");
ok(! $world->sighting_matrix->see_faction('eagle', 'Diver-1'), "Eagle faction can't see Diver anymore");
is(@{$world->armies}, 3, "3 mechas left");
is(@{$world->cemetery}, 1, "Gelgoog in the cemetery");

Gunpla::Test::clean_db('autotest', 1);
done_testing();
