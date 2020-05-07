use Mojo::Base -strict;

use v5.12;

use Test::More;
use Test::Mojo;

use lib 'lib';
use Data::Dumper;
use Gunpla::World;
use Gunpla::Test;
use MongoDB;

my $world = Gunpla::Test::test_bootstrap('duel.csv');
my $t = Test::Mojo->new('GunplaServer');

diag("Login");
$t->post_ok('/fe/login' => {Accept => '*/*'} => form => { game => 'autotest',
                                                          user => 'amuro' }) 
    ->status_is(302);

diag("When both players have to give commands the light is still on red");
$t->get_ok('/game/traffic-light?game=autotest')->status_is(200)->json_is(
    {
        status => 'RED'
    });

diag("Adding a command to RX78");
$t->post_ok('/game/command' => {Accept => '*/*'} => json => { game => 'autotest',
                                                              mecha => 'RX78', 
                                                              command => 'flywp',
                                                              params => 'WP-center',
                                                              velocity => 4 })
    ->status_is(200);
Gunpla::Test::dump_api($t);
diag("When only other players have to give commands the light is yellow");
$t->get_ok('/game/traffic-light?game=autotest')->status_is(200)->json_is(
    {
        status => 'YELLOW'
    });

diag("Command for Hyakushiki is emulated to avoid a second login");
my $client = MongoDB->connect();
my $db = $client->get_database('gunpla_autotest');
$db->get_collection('mechas')->update_one( { 'name' => 'Hyakushiki' }, { '$set' => { 'waiting' => 0 } } );

diag("No mechas on waiting: green light (game is elaborating)");
$t->get_ok('/game/traffic-light?game=autotest')->status_is(200)->json_is(
    {
        status => 'GREEN'
    });

Gunpla::Test::clean_db('autotest', 1);

done_testing();
