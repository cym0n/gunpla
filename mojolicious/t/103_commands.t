use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../stand-alone/lib';
use Gunpla::World;
use Gunpla::Test;

my $world = Gunpla::Test::test_bootstrap('t103.csv');
$world->armies->[1]->energy(4);
$world->save;
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("KO - Adding a command to RX78 - bad command");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'xxx',
                                                              params => 'WP-center',
                                                              velocity => 4 })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'bad command code'});

diag("KO - Adding a command to RX78 - bad target");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'flywp',
                                                              params => 'MEC-Hyakushiki',
                                                              velocity => 4 })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'bad target provided: MEC-Hyakushiki'});

diag("KO - Adding a command to RX78 - no velocity");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'flywp',
                                                              params => 'MEC-Hyakushiki',
                                                            })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'bad command: velocity needed'});


diag("OK - Adding a command to RX78");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'flywp',
                                                              params => 'WP-center',
                                                              velocity => 4 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'WP-center',
                    'command' => 'flywp',
                    'mecha' => 'RX78',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => 4,
                } });

diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=RX78')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=RX78')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'WP-center',
            'command' => 'flywp',
            'mecha' => 'RX78',
            'secondarycommand' => undef,
            'secondaryparams' => undef,
            'velocity' => 4,
        }
    }
);

diag("KO - Adding a command to Hyakushiki - Bad machinegun target");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'flywp',
                                                              params => 'WP-center',
                                                              secondarycommand => 'machinegun',
                                                              secondaryparams => 'MEC-Gelgoog',
                                                              velocity => 5,
 })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'Bad target provided: MEC-Gelgoog'});

diag("KO - Adding command to Hyakushiki - Rifle not compatible with machinegun");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'rifle',
                                                              params => 'MEC-RX78',
                                                              secondarycommand => 'machinegun',
                                                              secondaryparams => 'MEC-RX78',
                                                              velocity => 5,
 })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'Bad command: machinegun not allowed'});

diag("KO - Adding command to Hyakushiki - Not enough energy for sword");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'sword',
                                                              params => 'MEC-RX78',
 })
    ->status_is(400)
    ->json_is({ result => 'error',
                description => 'bad command: more energy needed'});



diag("Adding a command to Hyakushiki");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'Hyakushiki', 
                                                              command => 'flywp',
                                                              params => 'WP-center',
                                                              secondarycommand => 'machinegun',
                                                              secondaryparams => 'MEC-RX78',
                                                              velocity => 5,
 })
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' => 'WP-center',
                    'command' => 'flywp',
                    'mecha' => 'Hyakushiki',
                    'secondarycommand' => 'machinegun',
                    'secondaryparams' => 'MEC-RX78',
                    'velocity' => 5,
                } });

Gunpla::Test::dump_api($t);
diag("Veriying waiting mecha flag");
$t->get_ok('/game/mechas?game=autotest&mecha=Hyakushiki')->status_is(200)->json_is("/mecha/waiting" => 0);

diag("Getting the command");
$t->get_ok('/game/command?game=autotest&mecha=Hyakushiki')->status_is(200)->json_is(
    {
        'command' => {
            'params' => 'WP-center',
            'command' => 'flywp',
            'mecha' => 'Hyakushiki',
            'secondarycommand' => 'machinegun',
            'secondaryparams' => 'MEC-RX78',
            'velocity' => 5,
        }
    }
);

Gunpla::Test::clean_db('autotest', 1);


done_testing();


