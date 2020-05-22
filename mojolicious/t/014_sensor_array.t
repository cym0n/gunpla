use Mojo::Base -strict;

use v5.12;
use lib 'lib';

use Test::More;
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;


my $world = Gunpla::Test::test_bootstrap('t014.csv');
my $commands1 = { 'Dummy' => { command =>'wait' },
                 'RX78' => { command =>'land', params => 'SAR-0'}};
my $commands2 = { 'RX78' => { command =>'guard', params => '20000' }};
diag("RX78 lands on the sensor array and sights Dummy");
is(Gunpla::Test::emulate_commands($world, $commands1), 2);
is_deeply($world->get_events('RX78'), [ 'RX78 landed on sensor array 0', 'RX78 sighted Dummy' ]);
is_deeply($world->armies->[0]->status, [ 'landed', 'sensor-array-linked' ]);

Gunpla::Test::clean_db('autotest', 1);
done_testing();
