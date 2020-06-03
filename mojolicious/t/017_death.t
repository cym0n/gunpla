use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv', [20]);
$world->[1]->life(10);
my $commands = { 'RX78' => { command => 'rifle', params => 'MEC-Dummy'} };

is(Gunpla::Test::emulate_commands($world, $commands), 2, "RX78 shoot to a very weak dummy with a rifle");


diag("Checking mechas stats");
is($world->armies->[0]->position->x, -190);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[0]->energy, 638121);
is($world->armies->[1]->life, 770); #Damage 130 = 100 + (15 * 2)
is($world->armies->[1]->position->x, 200); #Damage 130 = 100 + (15 * 2)

Gunpla::Test::clean_db('autotest', 1);


done_testing();
