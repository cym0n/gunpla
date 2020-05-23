use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t009.csv', [20]);
my $commands = { 'RX78' => { command =>'rifle', params => 'MEC-Dummy'} };

is(Gunpla::Test::emulate_commands($world, $commands), 2);
$world->armies->[1]->velocity(6);

is_deeply($world->get_events('RX78'), [ 'RX78 hits with rifle Dummy' ]);
is_deeply($world->get_events('Dummy'), [ 'RX78 hits with rifle Dummy' ]);

is($world->armies->[1]->position->x, 2000); #Distance of 40000 from the target
is($world->armies->[0]->energy, 670001);

diag("Second try. Not enough energy");
$world->armies->[1]->position->x(0);
$world->armies->[0]->energy(0);
$commands = { 'RX78' => { command =>'rifle', params => 'MEC-Dummy'} };
is(Gunpla::Test::emulate_commands($world, $commands), 1);
is_deeply($world->get_events('RX78'), [ 'RX78: not enough energy for rifle' ]);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
