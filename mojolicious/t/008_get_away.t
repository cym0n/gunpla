use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t008.csv', [20, 3, 20]);
my $t = Test::Mojo->new('GunplaServer');
my $commands = { 'RX78' => { command =>'GET AWAY', params => 'WP-center', velocity => 10},
                 'Dummy' => { command => 'WAITING' } };

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("RX78 got away");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 reached destination: void space'
            }
        ]
    }
);
Gunpla::Test::dump_api($t);

diag("Check RX78 position");
is($world->armies->[0]->position->x, 230000);


Gunpla::Test::clean_db('autotest', 1);


done_testing();

