package Gunpla::Test;

use MongoDB;
use Data::Dumper;
use Test::More;
use Gunpla::World;

sub test_bootstrap
{
    my $scenario = shift;
    my $dice = shift || [];
    my $name = shift || 'autotest';
    clean_db($name);
    my $world = Gunpla::World->new(name => $name, dice_results => $dice);
    diag("Scenario: $scenario");
    $world->init_scenario($scenario);
    $world->save();
    return $world;
}


sub emulate_commands
{
    my $world = shift;
    my $commands = shift;
    for(keys %{$commands})
    {
        my $m = $world->get_mecha_by_name($_);
        if($m->waiting)
        {
            diag("Orders for " . $m->name . ": ". $commands->{$m->name}->{command});
            $m->waiting(0);
            $world->add_command($m->name, $commands->{$m->name});
        }
    }
    my $e = $world->action();
    $world->save;
    return $e;
}

sub clean_db
{
    my $world = shift || 'autotest';
    my $last = shift;
    if($last && $ENV{PRESERVE_MONGO})
    {
        diag("Test data about game $world preserved");
        return;
    }
    my $mongo = MongoDB->connect(); 
    my $masterdb = $mongo->get_database('gunpla__core');
    $masterdb->get_collection('games')->delete_one( { name => $world });
    my $db = $mongo->get_database('gunpla_' . $world);
    $db->drop();
    diag("Mongo data about game $world cleaned up!");
}

sub dump_api
{
    my $test = shift;
    my $file = shift || '/tmp/out1.log';
    open(my $log, "> $file");
    print {$log} Dumper($test->tx->res->json) . "\n";
    close($log);
}
1;
