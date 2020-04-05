#!/usr/bin/perl

use strict;
use v5.10;
use lib 'lib';
use MongoDB;
use Gunpla::World;
use Getopt::Long;
use Data::Dumper;

my $usage     = "Usage: $0 [COMMAND] [WORLD]\n\n";
#my $json    = '';
#my $userid = '';
#my $action = '';
#my $filename = '';
#GetOptions( 'json' => \$json, "userid=s" => \$userid ) or die $usage;

my $command = shift;
my $world = shift;

my $mongo = MongoDB->connect(); 
if($command eq 'init')
{
    say "Any data about old game $world will be lost...";
    my $db = $mongo->get_database('gunpla_' . $world);
    $db->drop();
    my $world_obj = Gunpla::World->new(name => $world);
    $world_obj->init();
    $world_obj->save();
    say "New world $world initiated";
}
elsif($command eq 'action')
{
    say "Loading world $world...";
    my $world_obj = Gunpla::World->new(name => $world);
    $world_obj->load();
    if($world_obj->all_ready())
    {
        $world_obj->fetch_commands_from_mongo();
        if($world_obj->all_ready_and_fetched())
        {
            my $e = $world_obj->action();
            say "$e events generated. Mechas ready for new commands";
            $world_obj->save();
            say "World saved. Action done";
        }
        else
        {
            die "Something went wrong. Impossible to acquire all the needed commands."
        }
    }
    else
    {
        say "Not all mecha ready for action. Exiting."
    }
}