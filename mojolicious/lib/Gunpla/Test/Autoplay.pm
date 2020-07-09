package Gunpla::Test::Autoplay;

use v5.10;
use Moo;
use Gunpla::Test;
use Data::Dumper;


has name => (
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
sub load
{
    my $self = shift;
    my $file = shift;
    open(my $story, "< $file");

    my $commands = {};
    my $tracing = {};
    my $reading_commands = 0;
    my $reading_tracing = 0;
    for(<$story>)
    {
        chomp;
        my $line = $_;
        next if $line =~ /^#/;
        if($line eq 'COMMANDS')
        {
            $reading_commands = 1;
            $reading_tracing = 0;
        }
        elsif($line eq 'TRACING')
        {
            $reading_tracing = 1;
            $reading_commands = 0;
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
}

sub run
{
    my $self = shift;
    say "\n" . $self->name. "\n";
    say $self->description . "\n\n";
    my $world = Gunpla::Test::test_bootstrap($self->map, $self->dice, $self->name, $self->configuration);
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
                    }
                }
            }
        }
        $events = $world->action();
        say "$events events generated";
        $world->save;
    }
    Gunpla::Test::clean_db('autotest', 1);
}

1;
