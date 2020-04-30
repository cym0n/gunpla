use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t008.csv', [20, 3, 20]);
my $commands = { 'RX78' => { command =>'GET AWAY', params => 'WP-center', velocity => 10},
                 'Dummy' => { command => 'WAITING' } };

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("RX78 got away");
is_deeply($world->get_events('RX78'), [ 'RX78 reached destination: void space' ]);

diag("Check RX78 position");
is($world->armies->[0]->position->x, 230000);

Gunpla::Test::clean_db('autotest', 1);

done_testing();

