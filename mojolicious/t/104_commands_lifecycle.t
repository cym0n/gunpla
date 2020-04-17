use Mojo::Base -strict;

use v5.12;

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
                    'velocity' => 4
                } });
diag("Adding a command to Hyakushiki");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'WP-alpha',
                                                              velocity => 5 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'WP-alpha',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Hyakushiki',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => 5
                } });

diag("Running script to elaborate actions");
say `script/gunpla.pl action autotest`;

my $t2 = Test::Mojo->new('GunplaServer');
diag("Getting the event - distance is exactly 140000");
$t2->get_ok('/game/event?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        events => [
            {
                mecha => 'RX78',
                message => 'RX78 sighted Hyakushiki'
            }
        ]
    }
);
diag("Check RX78 position");
$t2->get_ok('/game/mechas?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        mecha => {
            name => 'RX78',
            label => 'RX78',
            map_type => 'mecha',
            world_id => 'MEC-RX78',
            life => 1000,
            faction => 'wolf',
            position => { x => 64482, y => 0, z => 0 },
            waiting => 1,
            velocity => 4,
            max_velocity => 10,
        }
    }
);

diag("Check Hyakushiki position");
$t2->get_ok('/game/mechas?game=autotest&mecha=Hyakushiki')->status_is(200)->json_is(
    {
        mecha => {
            name => 'Hyakushiki',
            label => 'Hyakushiki',
            world_id => 'MEC-Hyakushiki',
            map_type => 'mecha',
            life => 1000,
            faction => 'eagle',
            position => { x => -75000, y => -12014, z => 0 },
            waiting => 0,
            velocity => 5,
            max_velocity => 10,
        }
    }
);






open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t2->tx->res->json) . "\n";
close($log);
diag("Drop gunpla_autotest db on local mongodb for final cleanup");
$db = $mongo->get_database('gunpla_autotest');
$db->drop();


done_testing();
