use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv');
my $commands = { 'RX78' => { command =>'flyhot', params => 'AST-0', velocity => 10},
                 'Dummy' => { command => 'wait' }};

is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("RX78 is nearby the asteroid");
is_deeply($world->get_events('RX78'), [ 'RX78 reached the nearby of asteroid 0' ]);

diag("Check RX78 position");
is($world->armies->[0]->position->x, 29423);
is($world->armies->[0]->position->y, 9423);
is($world->armies->[0]->position->z, 9424);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
