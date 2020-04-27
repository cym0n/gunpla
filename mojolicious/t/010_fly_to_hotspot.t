use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv');
my $t = Test::Mojo->new('GunplaServer');
my $commands = { 'RX78' => { command =>'FLY TO HOTSPOT', params => 'AST-0', velocity => 10},
                 'Dummy' => { command => 'WAITING' }};

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("RX78 is nearby the asteroid");
$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 reached the nearby of asteroid 0'
            }
        ]
    }
);

diag("Check RX78 position");
is($world->armies->[0]->position->x, 29423);
is($world->armies->[0]->position->y, 9423);
is($world->armies->[0]->position->z, 9424);

Gunpla::Test::dump_api($t);

Gunpla::Test::clean_db('autotest', 1);


done_testing();

