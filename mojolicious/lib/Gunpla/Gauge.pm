package Gunpla::Gauge;

use v5.10;
use Moo;
use Gunpla::Constants ":all";
use Data::Dumper;

has level => (
    is => 'rw',
    default => 0,
);

has max_level => (
    is => 'rw',
    default => 0,
);

has loop => (
    is => 'rw',
    default => 0
);

has accumulation => (
    is => 'rw',
    default => 0
);
has type => (
    is => 'rw',
    default => 0,
);

sub up
{
    my $self = shift;
    my $step = shift || 1;
    my $level = $self->level + $step;
    $self->level($level);
}

sub down
{
    my $self = shift;
    my $step = shift || 1;
    my $level = $self->level -$step;
    $level = 0 if $level < 0;
    $self->level($level);
}
sub mod
{
    my $self = shift;
    my $value = shift;
    my $new_value = $self->level + $value;
    $new_value = 0 if $new_value < 0;
    $self->level($new_value);
}

sub run
{
    my $self = shift;
    my $step = shift;
    if($self->accumulation)
    {
        $self->up($step);
        return 0;
    }
    else
    {
        $self->down($step);
        if($self->level == 0)
        {
            $self->reset if($self->loop);
            return 1;
        }
        else
        {
            return 0;
        }
    }
}

sub reset
{
    my $self = shift;
    $self->level($self->max_level);
}

sub to_mongo
{
    my $self = shift;
    return { max_level    => $self->max_level, 
             level        => $self->level,
             accumulation => $self->accumulation,
             loop         => $self->loop,
             type         => $self->type };
}

1;
