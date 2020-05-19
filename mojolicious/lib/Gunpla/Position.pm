package Gunpla::Position;

use Moo;
use POSIX;

has x => (
    is => 'rw',
);

has y => (
    is => 'rw',
);

has z => (
    is => 'rw',
);


sub clone
{
    my $self = shift;
    return $self->new( x => $self->x, y => $self->y, z => $self->z); 
}

sub as_string
{
    my $self = shift;
    my $naked = shift;
    if($naked)
    {
        return $self->x . ',' . $self->y . ',' . $self->z;
    }
    else
    {
        return '(' . $self->x . ', ' . $self->y . ', ' . $self->z . ')';
    }
}
sub anchor
{
    my $self = shift;
    return $self->new(x => 0, y => 0, z => 0);
}

sub vector
{
    my $self = shift;
    my $destination = shift;
    my $normal = shift;
    my $collapsed = shift;
    my %value; my %cursor;

    foreach my $coo ( 'x', 'y', 'z')
    {
        $value{$coo} = abs($destination->$coo - $self->$coo);
        $cursor{$coo} = $destination->$coo > $self->$coo ? 1 : $destination->$coo ==  $self->$coo ? 0 : -1;
    }
    my $versus = $self->new(x => $cursor{x}, y => $cursor{y}, z => $cursor{z});
    my $direction = $self->new(x => $value{x}, y => $value{y}, z => $value{z});


    if($normal)
    {
        my $anchor = $self->anchor;
        my $d = $anchor->distance($direction);
        return $anchor if($d == 0);
        $direction->x(sprintf("%.3f", $direction->x / $d));
        $direction->y(sprintf("%.3f", $direction->y / $d));
        $direction->z(sprintf("%.3f", $direction->z / $d));
    }
    if($collapsed)
    {
        return $self->new(
            x => $versus->x * $direction->x,
            y => $versus->y * $direction->y,
            z => $versus->z * $direction->z,
        );
    }
    else
    {
        return ( $versus, $direction );
    }
}

sub distance
{
    my $self = shift;
    my $destination = shift;
    my $floating = shift;
    my $vector = $self->vector($destination);
    my $result = sqrt(($vector->x ** 2) + ($vector->y ** 2) + ($vector->z ** 2));
    if($floating)
    {
        return sprintf("%.3f", $result)+0;
    }
    else
    {
        return ceil($result);
    }
}
sub away_from
{
    my $self = shift;
    my $target = shift;
    my $distance = shift;
    
    my ($versus, $direction) = $target->vector($self, 1);

    return $self->new(
        x => $self->x + ($versus->x * ceil($direction->x * $distance)),
        y => $self->y + ($versus->y * ceil($direction->y * $distance)),
        z => $self->z + ($versus->z * ceil($direction->z * $distance)),
    );
}
sub sum
{
    my $self = shift;
    my $second = shift;
    my $result = $self->new(
        x => $self->x + $second->x,
        y => $self->y + $second->y,
        z => $self->z + $second->z);
    my $anchor = $self->anchor;
    return $anchor->distance($result, 1);
}



sub longest
{
    my $self = shift;
    if($self->x > $self->y)
    {
        if($self->x > $self->z)
        {
            return 'x';
        }
        else
        {
            return 'z';
        }
    }
    else
    {
        if($self->y > $self->z)
        {
            return 'y';
        }
        else
        {
            return 'z';
        }
    }
}

sub course
{
    my $self = shift;
    my $destination = shift;
    my ($cursor, $vector) = $self->vector($destination);
    my $longest = $vector->longest();
    my $max_value = $vector->$longest;

    my $max_gap = 0;
    foreach my $coo ( 'x', 'y', 'z')
    {
        if($coo ne $longest && $vector->$coo != 0)
        {
            if($max_gap < int($max_value / $vector->$coo))
            {
                $max_gap = int($max_value / $vector->$coo)
            }
        }
    }
    $max_gap = $max_value if $max_gap == 0;
    return { direction => $cursor->$longest,
             axis => $longest,
             steps => $max_gap }
}

sub equals
{
    my $self = shift;
    my $p2 = shift;
    return ($self->x == $p2->x && $self->y == $p2->y && $self->z == $p2->z)
}

sub to_mongo
{
    my $self = shift;
    return {
        x => $self->x,
        y => $self->y,
        z => $self->z
    }
}

sub from_mongo
{
    my $package = shift;
    my $data = shift;
    return undef if ! $data;
    return $package->new($data);
}


return 1;
