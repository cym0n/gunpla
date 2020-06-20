package Gunpla::Test;

use MongoDB;
use Data::Dumper;
use Gunpla::World;

sub test_bootstrap
{
    my $scenario = shift;
    my $dice = shift || [];
    my $name = shift || 'autotest';
    my $config_file = shift;
    

    clean_db($name);
    my $world = Gunpla::World->new(name => $name, dice_results => $dice, log_file => "$name.log");
    $world->log("--- BOOSTRAP --- Scenario: $scenario");
    $world->log("  Tampered dice values") if @{$dice};
    $world->init_scenario($scenario, $config_file);
    $world->save();
    return $world;
}

sub reload
{
    my $world = shift;
    my $config_file = shift;
    my $name = $world->name;
    my $dice = $world->dice_results;
    my $inertia = $world->inertia;
    my $log_tracing = $world->log_tracing;
    my $log_stderr = $world->log_stderr;
    $world =  Gunpla::World->new(name => $name, dice_results => $dice, log_file => "$name.log", inertia => $inertia, log_tracing => $log_tracing, log_stderr => $log_stderr);
    $world->load($config_file);
    return $world;
}


sub emulate_commands
{
    my $world = shift;
    my $commands = shift;
    my $reload = shift;
    my $config_file = shift;
    if($reload)
    {
        $world = reload($world, $config_file);
    }
    for(keys %{$commands})
    {
        my $m = $world->get_mecha_by_name($_);
        if($m->waiting)
        {
            say STDERR "--- Orders for " . $m->name . ": ". $commands->{$m->name}->{command};
            $m->waiting(0);
            $m->cmd_fetched(1);
            $world->add_command($m->name, $commands->{$m->name});
        }
    }
    $world->fetch_commands_from_mongo();
    my $e = $world->action();
    $world->save;
    $world->log("Remaining dice results: " . @{$world->dice_results});
    return $e;
}

sub clean_db
{
    my $world = shift || 'autotest';
    my $last = shift;
    if($last && $ENV{PRESERVE_MONGO})
    {
        say STDERR "--- Test data about game $world preserved";
        return;
    }
    my $mongo = MongoDB->connect(); 
    my $masterdb = $mongo->get_database('gunpla__core');
    $masterdb->get_collection('games')->delete_one( { name => $world });
    my $db = $mongo->get_database('gunpla_' . $world);
    $db->drop();
    say STDERR "--- Mongo data about game $world cleaned up!";
}

sub dump_api
{
    my $test = shift;
    my $file = shift || '/tmp/out1.log';
    open(my $log, "> $file");
    print {$log} Dumper($test->tx->res->json) . "\n";
    close($log);
}

sub build_drift_dice
{
    my $direction = shift;
    my $quantity = shift;
    my @out = ();
    for(my $i = 0; $i < $quantity; $i++)
    {
        push @out, $direction;
    }
    return @out;
}
1;
