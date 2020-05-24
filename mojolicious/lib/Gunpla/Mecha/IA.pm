package Gunpla::Mecha::IA;

use v5.10;
use Moo;

has mecha_index => (
    is => 'ro'
);

has highlighted_events => (
    is => 'rw',
    default => sub { [] }
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


sub event_is
{
    my $self = shift;
    my $world = shift;
    my $mecha = shift;
    my $event = shift;

    my $events = $world->get_events($mecha);
    if(! @{$events})
    {
        $self->highlighted_events([]);
        return $event ? 0 : 1;
    }
    else
    {
        return 0 if(! $event);
        my @ord;
        if(@ord = grep { $_ =~ /$event/ } @{$events})
        {
            $self->highlighted_events(\@ord);
            return 1
        }
        else
        {
            $self->highlighted_events([]);
            return 0;
        }
    }
}

1;
