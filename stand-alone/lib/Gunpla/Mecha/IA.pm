package Gunpla::Mecha::IA;

use v5.10;
use Moo;
use Gunpla::Utils qw(get_game_events get_log_file get_timestamp);

has mecha_index => (
    is => 'ro'
);

has mecha => (
    is => 'ro',
);

has faction => (
    is => 'ro',
);


has game => (
    is => 'ro',
);

has package => (
    is => 'ro',
    default => 'Gunpla::Mecha::IA'
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
        package => $self->package,
        mecha_index => $self->mecha_index,
        mecha => $self->mecha,
        faction => $self->faction,
        game => $self->game,
    };
}

sub log
{
    my $self = shift;
    my $message = shift;
    $message = $self->mecha . ": " . $message;
    my $logfile = get_log_file($self->game);
    my $timestamp = get_timestamp($self->game);
    my $timestamp_toprint =  "[T" .  sprintf("%08d", $timestamp) . "]";
    my $final_message = join(" ", $timestamp_toprint, '[IAR]', $message);
    open(my $fh, '>> ' . $logfile);
    print {$fh} "$final_message\n";
    close($fh);
}
1;
