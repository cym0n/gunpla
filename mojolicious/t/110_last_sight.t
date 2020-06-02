use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('t110.csv');
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;
my $commands = { 'RX78' => { command => 'flywp', params => 'WP-beta', velocity => 10} };

diag("Hyakushiki command by API to test resume");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'flymec',
                                                              params => 'MEC-RX78',
                                                              velocity => 1 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'MEC-RX78',
                    'command' => 'flymec',
                    'mecha' => 'Hyakushiki',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => 1,
                } });

is(Gunpla::Test::emulate_commands($world, $commands, 1), 1);
$world = Gunpla::Test::reload($world);
is_deeply($world->get_events('Hyakushiki'), [ 'Hyakushiki lost contact with RX78' ]);

$t->get_ok('/game/targets?game=autotest&mecha=Hyakushiki&filter=last-sight')
    ->status_is(200)->json_is({
          'targets' => [
                         {
                           'x' => 87254, 
                           'y' => 0,
                           'world_id' => 'MEC-RX78',
                           'label' => 'mecha RX78 (87254, 0, 0) d:84090',
                           'map_type' => 'MEC',
                           'z' => 0,
                           'distance' => 84090,
                           'id' => 'RX78',
                         }
                       ]
        });
Gunpla::Test::dump_api($t);
$t->get_ok('/game/command?game=autotest&mecha=Hyakushiki&prev=1&available=1')
    ->status_is(200)->json_is({ command => {} });
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'last',
                                                              params => 'MEC-RX78',
                                                              velocity => 9 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' =>  'MEC-RX78',
                    'command' => 'last',
                    'mecha' => 'Hyakushiki',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => 9,
                } });
is(Gunpla::Test::emulate_commands($world, {}, 1), 1);
$world = Gunpla::Test::reload($world);
is_deeply($world->get_events('Hyakushiki'), [ 'Hyakushiki reached destination: last position of mecha RX78' ]);
is($world->armies->[1]->position->x, 87254);
is($world->armies->[1]->position->y, 0);
is($world->armies->[1]->position->z, 0);

Gunpla::Test::clean_db('autotest', 1);
done_testing();

