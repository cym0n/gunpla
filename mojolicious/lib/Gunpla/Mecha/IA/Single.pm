package Gunpla::Mecha::IA::Single;

use v5.10;
use Moo;

extends 'Gunpla::Mecha::IA';

has command => (
    is => 'ro',
    default => sub { { } }
);

has package => (
    is => 'ro',
    default => 'Gunpla::Mecha::IA::Single'
);


sub elaborate
{
    my $self = shift;
    my %c = %{$self->command} ; 
    return \%c;
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
