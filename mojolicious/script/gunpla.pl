#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::World;
use Getopt::Long;
use Data::Dumper;

my $usage     = "Usage: $0 [COMMAND] [WORLD] [--scenario=xxx] [--log=xxx]\n\n";
my $scenario  = undef;
my $logfile = undef;

GetOptions( 'scenario=s' => \$scenario, "log=s" => \$logfile ) or die $usage;
my $command = shift;
my $world = shift;

my $mongo = MongoDB->connect(); 
if($command eq 'init')
{
    to_log("Any data about old game $world will be lost...");
    my $db = $mongo->get_database('gunpla_' . $world);
    $db->drop();
    my $world_obj = Gunpla::World->new(name => $world);
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
    to_log("Loading world $world...");
    my $world_obj = Gunpla::World->new(name => $world);
    $world_obj->load();
    if($world_obj->all_ready())
    {
        $world_obj->fetch_commands_from_mongo();
        if($world_obj->all_ready_and_fetched())
        {
            my $e = $world_obj->action();
            $world_obj->save();
            to_log("$e events generated. Mechas ready for new commands");
        }
        else
        {
            die "Something went wrong. Impossible to acquire all the needed commands."
        }
    }
    else
    {
        to_log("Not all mecha ready for action. Exiting.");
    }
}

sub to_log
{
    my $message = shift;
    if($logfile)
    {
        open(my $lfh, ">> $logfile");
        say {$lfh} $message;
    }
    else
    {
        say $message;
    }
}
