use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use Gunpla::Position;

my $world = Gunpla::Test::test_bootstrap('dummy.csv');
my $t = Test::Mojo->new('GunplaServer');
$t->app->config->{no_login} = 1;

diag("RX78 Guards - KO - wrong clocks");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'guard',
                                                              params => '15000',})
    ->status_is(400)
    ->json_is({ result => 'error',
                description => "Bad target provided: 15000"
              });
diag("RX78 Guards - OK");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'guard',
                                                              params => '20000',})
    ->status_is(200)
    ->json_is({ result => 'OK',
                'command' => {
                    'params' =>  '20000',
                    'command' => 'guard',
                    'mecha' => 'RX78',
                    'secondarycommand' => undef,
                    'secondaryparams' => undef,
                    'velocity' => undef,
                } });
Gunpla::Test::dump_api($t);
is(Gunpla::Test::emulate_commands($world, {}, 1), 1);
$world = Gunpla::Test::reload($world);
is_deeply($world->get_events('RX78'), [ 'RX78 ended the guard' ]);
is($world->timestamp, 20000);

Gunpla::Test::clean_db('autotest', 1);
done_testing();


