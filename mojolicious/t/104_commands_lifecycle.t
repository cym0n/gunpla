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
$world->init();
$world->save();

my $t = Test::Mojo->new('GunplaServer');

diag("Adding a command to Diver");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Diver', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'center' })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'center',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Diver'
                } });
diag("Adding a command to Zaku");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Zaku', 
                                                              command => 'FLY TO WAYPOINT',
                                                              params => 'alpha' })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'alpha',
                    'command' => 'FLY TO WAYPOINT',
                    'mecha' => 'Zaku'
                } });

diag("Running script to elaborate actions");
say `script/gunpla.pl action autotest`;

my $t2 = Test::Mojo->new('GunplaServer');
diag("Check Diver position");
$t2->get_ok('/game/mechas?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        mecha => {
            name => 'Diver',
            faction => 'wolf',
            position => { x => 0, y => 0, z => 0 },
            waiting => 1
        }
    }
);

diag("Check Zaku position");
$t2->get_ok('/game/mechas?game=autotest&mecha=Zaku')->status_is(200)->json_is(
    {
        mecha => {
            name => 'Zaku',
            faction => 'eagle',
            position => { x => -100000, y => -100001, z => 0 },
            waiting => 0
        }
    }
);

diag("Getting the event");
$t2->get_ok('/game/event?game=autotest&mecha=Diver')->status_is(200)->json_is(
    {
        event => {
            mecha => 'Diver',
            message => 'Diver reached destination'
        }
    }
);




open(my $log, "> /tmp/out1.log");
print {$log} Dumper($t2->tx->res->json) . "\n";
close($log);
#diag("Drop gunpla_autotest db on local mongodb for final cleanup");
#$db = $mongo->get_database('gunpla_autotest');
#$db->drop();


done_testing();
