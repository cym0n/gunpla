package Gunpla::Mecha::IA::Single;

use v5.10;
use Moo;

extends 'Gunpla::Mecha::IA';

has command => (
    is => 'ro',
    default => sub { { } }
);

sub elaborate
{
    my $self = shift;
    return $self->command;
}

1;
