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

sub to_mongo
{
    my $self = shift;
    return { 
        package => __PACKAGE__,
        mecha_index => $self->mecha_index,
        mecha => $self->mecha,
        game => $self->game,
        command => $self->command,
    };
}

1;
