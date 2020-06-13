use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my @dice = (Gunpla::Test::build_drift_dice(1, 7000), Gunpla::Test::build_drift_dice(0, 7000), Gunpla::Test::build_drift_dice(1, 7000), Gunpla::Test::build_drift_dice(0, 7000)); 

my $world = Gunpla::Test::test_bootstrap('t018.csv', \@dice);
my $t = Test::Mojo->new('GunplaServer');

is(Gunpla::Test::emulate_commands($world, {
    'RX78'       => { command => 'flywp', params => 'WP-asgard',    velocity => 6 },
    'Guncannon'  => { command => 'flywp', params => 'WP-midgard',   velocity => 6 },
    'Sandrock'   => { command => 'flywp', params => 'WP-alfheim',   velocity => 6 },
    'Hyakushiki' => { command => 'flywp', params => 'WP-jotunheim', velocity => 6 },
}), 2);
is_deeply($world->get_events('RX78'), [ 'RX78 reached destination: waypoint asgard' ], "RX78 waiting, Sandrock waiting, Guncannon not");
is(Gunpla::Test::emulate_commands($world, {
    'RX78'       => { command => 'support', params => 'MEC-Guncannon' },
    'Sandrock'   => { command => 'flywp', params => 'WP-midgard',   velocity => 6 },
}), 2, "RX78 support request for Guncannon");
is_deeply($world->get_events('RX78'), [ 'RX78 ask for support to Guncannon' ], "(RX78) RX78 support request");
is_deeply($world->get_events('Guncannon'), [ 'RX78 ask for support to Guncannon' ], "(Guncannon) RX78 support request");
is($world->armies->[0]->position->y, 2167, "RX78 position after support request (it's drifting)");
is($world->armies->[1]->position->y, -3333, "Guncannon position receiving support request");
is($world->armies->[0]->waiting, 1, "RX78 is waiting");
is($world->armies->[1]->waiting, 1, "Guncannon is waiting");
is(Gunpla::Test::emulate_commands($world, {
    'RX78'       => { command => 'flywp', params => 'WP-red' },
    'Guncannon'   => { command => 'support', params => 'MEC-Sandrock' },
}), 2, "Guncannon support request for Sandrock");
is_deeply($world->get_events('Guncannon'), [ 'Guncannon ask for support to Sandrock' ], "(Guncannon) Guncannon support request");
is_deeply($world->get_events('Sandrock'), [ 'Guncannon ask for support to Sandrock' ], "(Sandrock) Sandrock support request");
is($world->armies->[1]->position->y, -5666, "Guncannon position after support request (it's still heading midgard)");
is($world->armies->[2]->position->y, -5666, "Sandrock position receiving support request");
is($world->armies->[1]->waiting, 1, "Guncannon is waiting");
is($world->armies->[2]->waiting, 1, "Sandrock is waiting");

Gunpla::Test::clean_db('autotest', 1);
done_testing();
