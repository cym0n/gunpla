#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use lib '../stand-alone/lib';
use MongoDB;
use Gunpla::World;
use Getopt::Long;
use Data::Dumper;
use DateTime;

my $usage     = "Usage: $0 [COMMAND] [WORLD] [--scenario=xxx] [--log=xxx]\n\n";
my $scenario  = undef;
my $logfile = undef;

GetOptions( 'scenario=s' => \$scenario, "log=s" => \$logfile ) or die $usage;
my $command = shift;
my $world = shift;

my $mongo = MongoDB->connect(); 
if($command eq 'init')
{
    die "No world" if ! $world;
    $logfile = "server-$world.log" if ! $logfile;
    to_log("Any data about old game $world will be lost...");
    my $db = $mongo->get_database('gunpla_' . $world);
    $db->drop();
    my $world_obj = Gunpla::World->new(name => $world, log_file => $logfile);
    if($scenario)
    {
        to_log("Scenario from file $scenario");
        $world_obj->init_scenario($scenario);
    }
    else
    {
        $world_obj->init();
    }
    $world_obj->save();
    to_log("New world $world initiated");
}
elsif($command eq 'action')
{
    my $world_obj = load_world($world);
    run_world($world_obj);
}
elsif($command eq 'daemon')
{
    while(1)
    {
        my $world_obj = load_world($world, 1000);
        run_world($world_obj);
        sleep 10;    
    }
}

sub to_log
{
    my $message = shift;
    if($logfile)
    {
        open(my $lfh, ">> $logfile");
        say {$lfh} "[TXXXXXXXX] [SCR] $message";
    }
    else
    {
        say $message;
    }
}

sub load_world
{
    my $name = shift;
    my $save_every = shift;
    to_log("Loading world $name...");
    my $world_obj = Gunpla::World->new(name => $name, save_every => $save_every);
    $world_obj->load();
    if(! @{$world_obj->armies})
    {
        die "No mechas loaded. Check world name.";
    }
    return $world_obj;
}

sub run_world
{
    my $world_obj = shift;
    my $steps = shift;
    if($world_obj->all_ready())
    {
        $world_obj->fetch_commands_from_mongo();
        if($world_obj->all_ready_and_fetched())
        {
            my $start = DateTime->now;
            my $starting_timestamp = $world_obj->timestamp;
            my $e = $world_obj->action($steps);
            $world_obj->save();
            my $end = DateTime->now;
            my $ending_timestamp = $world_obj->timestamp;
            my $secs = $end->epoch - $start->epoch;
            my $clocks = $ending_timestamp - $starting_timestamp;
            if($e)
            {
                to_log("Starting timestamp: $starting_timestamp");
                to_log("Ending timestamp: $ending_timestamp");
                to_log("Action elaboration took $secs seconds, $clocks clocks elaborated");
                to_log("$e events generated. Mechas ready for new commands");
            }
        }
        else
        {
            die "Something went wrong. Impossible to acquire all the needed commands."
        }
    }
    else
    {
       to_log("Not all mecha ready for action.");
    }
}
