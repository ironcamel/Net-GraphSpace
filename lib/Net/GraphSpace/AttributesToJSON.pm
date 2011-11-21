package Net::GraphSpace::AttributesToJSON;
use Moose::Role;
use v5.10;

sub TO_JSON {
    my ($self) = @_;
    my @attrs = $self->meta->get_all_attributes;
    return { map $self->_affinitize($_), @attrs };
}

sub _affinitize {
    my ($self, $attr) = @_;
    my $name = $attr->name;
    my $value = $self->$name;
    return if not defined $value;
    given ($attr->type_constraint) {
        when ($_->equals('Str')) { "$value"   }
        when ($_->equals('Int')) { int $value }
    }
    return $name => $value;
}

1;
