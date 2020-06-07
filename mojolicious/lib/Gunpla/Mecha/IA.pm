package Gunpla::Mecha::IA;

use v5.10;
use Moo;
use Gunpla::Utils qw(get_game_events);

has mecha_index => (
    is => 'ro'
);

has mecha => (
    is => 'ro',
);

has game => (
    is => 'ro',
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
    my $event = shift;

    my $events = get_game_events($self->game, $self->mecha);
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

sub to_mongo
{
    my $self = shift;
    return { 
        package => __PACKAGE__,
        mecha_index => $self->mecha_index,
        mecha => $self->mecha,
        game => $self->game,
    };
}
1;
