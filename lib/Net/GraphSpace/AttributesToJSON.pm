package Net::GraphSpace::AttributesToJSON;
use Moose::Role;
use MooseX::Method::Signatures;
use v5.10;

method TO_JSON() {
    my @attrs = $self->meta->get_all_attributes;
    return { map $self->_affinitize($_), @attrs };
}

method _affinitize($attr) {
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
