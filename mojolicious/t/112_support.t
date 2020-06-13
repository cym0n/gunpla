use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t112.csv');
my $t = Test::Mojo->new('GunplaServer');

is(Gunpla::Test::emulate_commands($world, {
    'RX78'       => { command => 'flywp', params => 'WP-asgard',    velocity => 6 },
    'Guncannon'  => { command => 'flywp', params => 'WP-midgard',   velocity => 6 },
    'Sandrock'   => { command => 'flywp', params => 'WP-alfheim',   velocity => 6 },
    'Hyakushiki' => { command => 'flywp', params => 'WP-jotunheim', velocity => 6 },
}), 2);
is_deeply($world->get_events('RX78'), [ 'RX78 reached destination: waypoint asgard' ], "RX78 waiting, Guncannon not");

$t->app->config->{no_login} = 1;
diag("RX78 sees Guncannon as potential support (Sandrock is in waiting)");
$t->get_ok('/game/targets?game=autotest&mecha=RX78&filter=friends-no-wait')
    ->status_is(200)
    ->json_is(
        {
          'targets' => 
                    [
                        {
                           'world_id' => 'MEC-Guncannon',
                           'map_type' => 'MEC',
                           'x' => '200000',
                           'id' => 'Guncannon',
                           'z' => '0',
                           'y' => '-1000',
                           'distance' => 2000,
                           'label' => 'mecha Guncannon (200000, -1000, 0) d:2000'
                         },
                    ]
        });
diag("RX78 ask Sandrock for support - waiting mecha - KO");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'support',
                                                              params => 'MEC-Sandrock',})
    ->status_is(400)
    ->json_is({
          'result' => 'error',
          'description' => 'Bad target provided: MEC-Sandrock'
    });
diag("RX78 ask Hyakushiki for support - enemy mecha - KO");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'support',
                                                              params => 'MEC-Hyakushiki',})
    ->status_is(400)
    ->json_is({
          'result' => 'error',
          'description' => 'Bad target provided: MEC-Hyakushiki'
    });
diag("RX78 ask Guncannon for support - OK");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'support',
                                                              params => 'MEC-Guncannon',})
    ->status_is(200)
    ->json_is({
          'result' => 'OK',
          'command' => {
                    'params' =>  'MEC-Guncannon',
                    'command' => 'support',
                    'mecha' => 'RX78',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => undef,
                } });
Gunpla::Test::dump_api($t);



Gunpla::Test::clean_db('autotest', 1);
done_testing();
