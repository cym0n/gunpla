use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;

diag("Drop gunpla_autotest db on local mongodb");
my $mongo = MongoDB->connect(); 
my $db = $mongo->get_database('gunpla_autotest');
$db->drop();


diag("Generate a world and save it on db");
my $world = Gunpla::World->new(name => 'autotest');
$world->init_test('duel');
$world->save();

my $t = Test::Mojo->new('GunplaServer');

diag("Adding a command to RX78");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'WP-center',
                                                              velocity => 4 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'WP-center',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'RX78',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => 4,
                } });
open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t->tx->res->json) . "\n";
close($log);

diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=RX78')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'WP-center',
            'command' => 'FLY TO WAYPOINT',
            'mecha' => 'RX78',
            'secondarycommand' => undef,
            'secondaryparams' => undef,
            'velocity' => 4,
        }
    }
);

diag("Adding a command to Hyakushiki");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'WP-center',
                                                              secondarycommand => 'machinegun',
                                                              secondaryparams => 'RX78',
                                                              velocity => 5,
 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'WP-center',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Hyakushiki',
                    'secondarycommand' => 'machinegun',
                    'secondaryparams' => 'RX78',
                    'velocity' => 5,
                } });

diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=Hyakushiki')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=Hyakushiki')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'WP-center',
            'command' => 'FLY TO WAYPOINT',
            'mecha' => 'Hyakushiki',
            'secondarycommand' => 'machinegun',
            'secondaryparams' => 'RX78',
            'velocity' => 5,
        }
    }
);









diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();


