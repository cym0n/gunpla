use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv', [20, 0]);
$world->armies->[0]->position->x(1000);
my $t = Test::Mojo->new('GunplaServer');
my $commands = { 'RX78' => { command => 'SWORD ATTACK', params => 'MEC-Dummy'},
                 'Dummy' => { command => 'WAITING' } };

is(Gunpla::Test::emulate_commands($world, $commands), 2);

diag("=== RX78 slash");
diag("Checking event generation (using API)");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 slash with sword mecha Dummy'
            }
        ]
    }
);
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'RX78 slash with sword mecha Dummy'
            }
        ]
    }
);

diag("Checking mechas stats");
is($world->armies->[0]->position->x, -190);
is($world->armies->[0]->attack_limit, 0);
is($world->armies->[0]->attack_gauge, 0);
is($world->armies->[1]->life, 770); #Damage 130 = 100 + (15 * 2)
is($world->armies->[1]->position->x, 200); #Damage 130 = 100 + (15 * 2)

Gunpla::Test::clean_db('autotest', 1);


done_testing();

