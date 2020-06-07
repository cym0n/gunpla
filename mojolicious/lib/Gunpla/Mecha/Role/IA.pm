package Gunpla::Mecha::Role::IA;

use strict;
use v5.10;
use Moo::Role;

has ia => (
    is => 'rw',
    default => 0
);

has brain_module => (
    is => 'rw',
    default => undef
);

sub install_ia
{
    my $self = shift;
    my $game = shift;
    my $index = shift;
    my $module = shift;
    my $conf = shift;
    if($conf)
    {
        $conf->{mecha_index} = $index;
    }
    else
    {
        $conf = { mecha_index => $index };
    }
    $conf->{game} = $game;
    $conf->{mecha} = $self->name;
    eval("require $module");
    die $@ if $@;
    my $brain = $module->new(%{$conf});
    $self->brain_module($brain);
    $self->ia(1);
}

sub ia_from_mongo
{
    my $self = shift;
    my $conf = shift;
    my $package = $conf->{package};
    delete $conf->{package};
    eval("require $package");
    die $@ if $@;
    my $brain = $package->new(%{$conf});
    $self->brain_module($brain);
    $self->ia(1);
}


sub decide
{
    my $self = shift;
    my $command = $self->brain_module->elaborate();
    return $command;
}

sub ia_to_mongo
{
    my $self = shift;
    if($self->ia)
    {
        return $self->brain_module->to_mongo();
    }
    else
    {
        return undef;
    }
}

1;
