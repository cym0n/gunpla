use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t008.csv');
my $commands = { 
    'RX78-1' => { command =>'away', params => 'WP-center', velocity => 10}, 
    'RX78-2' => { command =>'away', params => 'WP-blue', velocity => 10} #Away from the position he is
};

is(Gunpla::Test::emulate_commands($world, $commands), 2);

diag("RX78 1 and 2 got away");
is_deeply($world->get_events('RX78-1'), [ 'RX78-1 reached destination: void space' ]);
is_deeply($world->get_events('RX78-2'), [ 'RX78-2 reached destination: void space' ]);

is($world->armies->[0]->position->x, 230000, "RX78-1 position");
is($world->armies->[1]->position->x, 230000, "RX78-2 position");

Gunpla::Test::clean_db('autotest', 1);

done_testing();

