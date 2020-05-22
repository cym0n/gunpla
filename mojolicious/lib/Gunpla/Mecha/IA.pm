package Gunpla::Mecha::IA;

use v5.10;
use Moo;

has mecha_index => (
    is => 'ro'
);

sub elaborate
{
    return { 
        command => 'wait',
        params => undef,
        secondarycommand => undef,
        secondaryparams => undef,
        velocity => undef
    }
}
