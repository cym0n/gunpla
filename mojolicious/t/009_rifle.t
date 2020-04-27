use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t009.csv', [20]);
my $t = Test::Mojo->new('GunplaServer');
my $commands = { 'RX78' => { command =>'RIFLE', params => 'MEC-Dummy'},
                 'Dummy' => { command => 'FLY TO WAYPOINT', params => 'WP-blue', velocity => 6 } };

is(Gunpla::Test::emulate_commands($world, $commands), 2);
$world->armies->[1]->velocity(6);

$t->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 hits with rifle Dummy'
            }
        ]
    }
);
$t->get_ok('/game/event?game=autotest&mecha=Dummy')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'Dummy',
                message => 'RX78 hits with rifle Dummy'
            }
        ]
    }
);
is($world->armies->[1]->position->x, 2000);


Gunpla::Test::clean_db('autotest', 1);


done_testing();

