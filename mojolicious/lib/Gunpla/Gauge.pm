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
    my $level = $self->level +1;
    $self->level($level);
}

sub down
{
    my $self = shift;
    my $level = $self->level -1;
    $level = 0 if $level < 0;
    $self->level($level);
}

sub run
{
    my $self = shift;
    if($self->accumulation)
    {
        $self->up;
        return 0;
    }
    else
    {
        $self->down;
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
