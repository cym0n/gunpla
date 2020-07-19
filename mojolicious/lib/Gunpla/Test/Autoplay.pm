package Gunpla::Test::Autoplay;

use v5.10;
use Moo;
use Gunpla::Test;
use DateTime;
use Data::Dumper;
use Gunpla::Utils qw(copy_table update_log_file);


has name => (
    is => 'rw'
);
has title => (
    is => 'rw'
);
has description => (
    is => 'rw'
);
has map => (
    is => 'rw'
);
has configuration => (
    is => 'rw'
);
has dice => (
    is => 'rw'
);
has commands => (
    is => 'rw'
);
has tracing => (
    is => 'rw'
);
has snapshots => (
    is => 'rw'
);
has templates => (
    is => 'rw',
    default => undef
);
sub load
{
    my $self = shift;
    my $file = shift;
    my $title = shift;
    $self->title($title);
    open(my $story, "< $file");

    my $commands = {};
    my $tracing = {};
    my $snapshots = {};
    my $reading_commands = 0;
    my $reading_tracing = 0;
    my $reading_snapshots = 0;
    for(<$story>)
    {
        chomp;
        my $line = $_;
        next if $line =~ /^#/;
        if($line eq 'COMMANDS')
        {
            $reading_commands = 1;
            $reading_tracing = 0;
            $reading_snapshots = 0;
        }
        elsif($line eq 'TRACING')
        {
            $reading_tracing = 1;
            $reading_commands = 0;
            $reading_snapshots = 0;
        }
        elsif($line eq 'SNAPSHOTS')
        {
            $reading_tracing = 0;
            $reading_commands = 0;
            $reading_snapshots = 1;
        }
        else
        {
            if($reading_commands)
            {
                my @values = split ';', $line;
                push @{$commands->{$values[0]}}, { command => $values[1],
                                                   params => $values[2],
                                                   secondarycommand => $values[3],
                                                   secondaryparams => $values[4],
                                                   velocity => $values[5] };
            }
            elsif($reading_tracing)
            {
                my @values = split ';', $line;
                my @targets = split ',', $values[2];
                $tracing->{$values[0]}->{$values[1]} = \@targets;
            }
            elsif($reading_snapshots)
            {
                my @values = split ';', $line;
                $snapshots->{$values[0]}->{$values[1]} = $values[2];
            }
            else
            {
                if($line =~ /^(.*?):(.*)$/)
                {
                    my $element = $1;
                    my $value = $2;
                    if($element eq 'NAME')
                    {
                        $self->name($value);
                    }
                    elsif($element eq 'DESCRIPTION')
                    {
                        $self->description($value);
                    }
                    elsif($element eq 'MAP')
                    {
                        $self->map($value);
                    }
                    elsif($element eq 'CONFIGURATION')
                    {
                        $self->configuration($value);
                    }
                    elsif($element eq 'TEMPLATES')
                    {
                        $self->templates($value);
                    }
                    elsif($element eq 'DICE')
                    {
                        my @dice = split ",", $value;
                        $self->dice(\@dice);
                    }
                    else
                    {
                        die "Malformed file $file";
                    }
                }
                else
                {
                    die "Malfomed file $file";
                }
            }
        }
    }
    if(%{$commands})
    {
        $self->commands($commands);
    }
    else
    {
        die "Malformed file $file";
    }
    $self->tracing($tracing);
    $self->snapshots($snapshots);
}

sub run
{
    my $self = shift;
    my $snap = shift;
    say "\n" . $self->name. "\n";
    say $self->description . "\n";
    say $self->title . "\n";
    my $logfile = "log/" . $self->name . "_" . DateTime->now->ymd('') . DateTime->now->hms('') . ".log";
    say "Logfile is $logfile\n";
    my $world;
    if($snap)
    {
        $world = Gunpla::World->new(name => $self->name, dice_results => $self->dice, log_file => $logfile);
        $world = $self->load_snapshot($world, $snap);
    }
    else
    {
        $world = Gunpla::Test::test_bootstrap($self->map, $self->dice, $self->name, $self->configuration, $self->templates, $logfile);
    }
    $world->log(undef, ">>>>>>>>>>\n>>> " . $self->title . "\n>>>>>>>>>>", 1);
    my $events = 1;
    while($events)
    {
        foreach my $m (@{$world->armies})
        {
            if($m->waiting)
            {
                if(exists $self->commands->{$m->name}->[$m->cmd_index])
                {
                    my $c = $self->commands->{$m->name}->[$m->cmd_index];
                    say "Orders for " . $m->name . ": ". $world->command_string($c);
                    $m->waiting(0);
                    $m->cmd_fetched(1);
                    $world->add_command($m->name, $c);
                    if(exists $self->tracing->{$m->name}->{$m->cmd_index})
                    {
                        $world->log_tracing($self->tracing->{$m->name}->{$m->cmd_index});
                        say "Tracing updated: " . join ", ", @{$self->tracing->{$m->name}->{$m->cmd_index}};
                    }
                    if(exists $self->snapshots->{$m->name}->{$m->cmd_index})
                    {
                        my $snap = $self->take_snapshot($world, $self->snapshots->{$m->name}->{$m->cmd_index});
                        say "Snapshot taken: $snap";
                    }
                }
            }
        }
        $events = $world->action();
        say "$events events generated" if $events;
        $world->save;
    }
    Gunpla::Test::clean_db('autotest', 1);
    say `cat $logfile`;
}

sub take_snapshot
{
    my $self = shift;
    my $world = shift;
    my $snap_name = shift;
    my $snap = 'snap_' . $world->name . '_' . $snap_name;
    Gunpla::Test::clean_db($snap);
    $world->save($snap);
    Gunpla::Utils::copy_table('events', $world->name, $snap);
    return $snap;
}

sub load_snapshot
{
    my $self = shift;
    my $world = shift;
    my $snap_name = shift;
    say "Loading snapshot $snap_name";
    Gunpla::Test::clean_db($world->name);

    my @tables = qw ( available_commands events map mechas status );
    for(@tables)
    {
        Gunpla::Utils::copy_table($_, $snap_name, $world->name);
    }
    Gunpla::Utils::update_log_file($world->name, $world->log_file);
    my $new_world = Gunpla::Test::reload($world, $self->configuration); 
    $new_world->log("INI", "loaded from snapshot $snap_name");
    say "Loaded mechas: " . @{$new_world->armies};
    return $new_world;
}

1;
