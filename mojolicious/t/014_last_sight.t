use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv');
#Fake last seen command just to test syntax
my $commands = { 'RX78' => { command =>'last', params => '25000,5000,5000', velocity => 10},
                 'Dummy' => { command => 'wait' }};
is(Gunpla::Test::emulate_commands($world, $commands), 1);

diag("RX78 reaches the position in space");
is_deeply($world->get_events('RX78'), [ 'RX78 reached destination: void space' ]);

diag("Check RX78 position");
is($world->armies->[0]->position->x, 25000);
is($world->armies->[0]->position->y, 5000);
is($world->armies->[0]->position->z, 5000);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
