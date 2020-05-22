package Gunpla::Mecha::Role::IA;

use strict;
use v5.10;
use Moo::Role;

has ia => (
    is => 'ro',
    default => 0
);

has brain_module => (
    is => 'ro',
    default => undef
);

sub decide
{
    my $self = shift;
    my $events = undef;#TODO fetch events
    my $command = $self->brain_module->elaborate($self, $events);
    return $command;
}


1;
