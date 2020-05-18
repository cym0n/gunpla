use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;


my $world = Gunpla::Test::test_bootstrap('duel.csv');
my $t = Test::Mojo->new('GunplaServer');

diag("Login");
$t->post_ok('/fe/login' => {Accept => '*/*'} => form => { game => 'autotest',
                                                          user => 'amuro' }) 
    ->status_is(302);

diag("Mechas read API - all");
$t->get_ok('/game/mechas?game=autotest')->status_is(200)->json_has('/mechas');

diag("Mechas read API - single");
$t->get_ok('/game/mechas?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        mecha => {
            name => 'RX78',
            label => 'RX78',
            world_id => 'MEC-RX78',
            map_type => 'mecha',
            life => 1000,
            faction => 'wolf',
            position => { x => 75000, y => 0, z => 0 },
            waiting => 1,
            velocity => 0,
            max_velocity => 10,
            available_max_velocity => 10,
            energy => 700000,
        }
    }
);

diag("Mechas read API - single - not allowed");
$t->get_ok('/game/mechas?game=autotest&mecha=Zaku')->status_is(403)->json_is(
    {
        error => 'Mecha not owned'
    }
);

diag("Waypoints read API");
$t->get_ok('/game/targets?game=autotest&filter=waypoints')->status_is(200)->json_is(
{
    'targets' => [
        {
            'id' => 'alpha',
            'world_id' => 'WP-alpha',
            'label' => 'waypoint alpha (0, -200000, 0)',
            'map_type' => 'WP',
            'x' => '0',
            'y' => '-200000',
            'z' => '0',
            'distance' => undef
        },
        {
            'id' => 'blue',
            'world_id' => 'WP-blue',
            'label' => 'waypoint blue (75000, 0, 0)',
            'map_type' => 'WP',
            'x' => '75000',
            'y' => '0',
            'z' => '0',
            'distance' => undef,
        },
        {
            'id' => 'center',
            'world_id' => 'WP-center',
            'label' => 'waypoint center (0, 0, 0)',
            'map_type' => 'WP',
            'x' => '0',
            'y' => '0',
            'z' => '0',
            'distance' => undef,
        },
        {
            'id' => 'magellan',
            'world_id' => 'WP-magellan',
            'label' => 'waypoint magellan (50000, 10000, 10000)',
            'map_type' => 'WP',
            'x' => '50000',
            'y' => '10000',
            'z' => '10000',
            'distance' => undef,
        },
        {
            'id' => 'red',
            'world_id' => 'WP-red',
            'label' => 'waypoint red (-75000, 0, 0)',
            'map_type' => 'WP',
            'x' => '-75000',
            'y' => '0',
            'z' => '0',
            'distance' => undef,
        }
    ]}
);
Gunpla::Test::dump_api($t);
#diag("Waypoints read API - single");
#$t->get_ok('/game/waypoints?game=autotest&waypoint=center')->status_is(200)->json_is(
#    {
#        waypoint => {
#            name => 'center',
#            label => 'center',
#            map_type => 'waypoint',
#            world_id => 'WP-center',
#            x => 0,
#            y => 0,
#            z => 0
#        }
#    }
#);

Gunpla::Test::clean_db('autotest', 1);

done_testing();
