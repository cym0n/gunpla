use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv', [20, 0]);
$world->armies->[0]->position->x(1000);
my $commands = { 'RX78' => { command => 'sword', params => 'MEC-Dummy'},
                 'Dummy' => { command => 'wait' } };

is(Gunpla::Test::emulate_commands($world, $commands), 2);

diag("=== RX78 slash");
diag("Checking event generation");
is_deeply($world->get_events('RX78'), [ 'RX78 slash with sword mecha Dummy' ]);
is_deeply($world->get_events('Dummy'), [ 'RX78 slash with sword mecha Dummy' ]);

diag("Checking mechas stats");
is($world->armies->[0]->position->x, -190);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[0]->energy, 638121);
is($world->armies->[1]->life, 770); #Damage 130 = 100 + (15 * 2)
is($world->armies->[1]->position->x, 200); #Damage 130 = 100 + (15 * 2)

Gunpla::Test::clean_db('autotest', 1);


done_testing();

