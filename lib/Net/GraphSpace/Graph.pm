package Net::GraphSpace::Graph;
use Moose;
use MooseX::Method::Signatures;

use Carp qw(croak);
use JSON qw(decode_json);
use Net::GraphSpace::Types;

has name        => (is => 'rw', isa => 'Str', required => 1);
has description => (is => 'rw', isa => 'Str');
has tags        => (is => 'rw', isa => 'ArrayRef');

has _nodes => (
    is => 'rw',
    isa => 'ArrayRef[Net::GraphSpace::Node]',
    default => sub { [] },
);
has _edges      => (
    is => 'rw',
    isa => 'ArrayRef[Net::GraphSpace::Edge]',
    default => sub { [] },
);
has _nodes_map  => (
    is => 'rw',
    isa => 'HashRef[Net::GraphSpace::Node]',
    default => sub { {} },
);

method add_node(Net::GraphSpace::Node $node) {
    push @{ $self->_nodes }, $node;
    $self->_nodes_map->{$node->id} = $node;
}

method add_nodes($nodes) { $self->add_node($_) foreach @$nodes }

method add_edge(Net::GraphSpace::Edge $edge) {
    croak "No such node corresponds to the edge's source node " . $edge->source
        unless $self->_nodes_map->{$edge->source};
    croak "No such node corresponds to the edge's target node " . $edge->target
        unless $self->_nodes_map->{$edge->target};
    push @{ $self->_edges }, $edge;
}

method add_edges($edges) { $self->add_edge($_) foreach @$edges }

method TO_JSON() {
    return {
        metadata => {
            map { defined($self->$_) ? ( $_ => $self->$_ ) : () }
                qw(name description tags)
        },
        graph => {
            data => { nodes => $self->_nodes, edges => $self->_edges }
        }
    };
}

method new_from_http_response($class: HTTP::Response $res) {
    my $data = decode_json($res->content);

    my $metadata = $data->{metadata};
    my $graph = Net::GraphSpace::Graph->new(name => $metadata->{name});
    $graph->description($metadata->{description})
        if defined $metadata->{description};
    $graph->tags($metadata->{tags}) if defined $metadata->{tags};

    my $graphdata = $data->{graph}{data};
    for my $node (@{$graphdata->{nodes}}) {
        $graph->add_node(Net::GraphSpace::Node->new(%$node));
    }
    for my $edge (@{$graphdata->{edges}}) {
        $graph->add_edge(Net::GraphSpace::Edge->new(%$edge));
    }

    return $graph;
}

=head1 SYNOPSIS

    my $graph = Net::GraphSpace::Graph->new(
        name => 'graph x15'
        description => 'a great graph',
        tags => ['foo', 'bar'],
    );
    my $node1 = Net::GraphSpace::Node->new(id => 1, label => 'A');
    my $node2 = Net::GraphSpace::Node->new(id => 2, label => 'B');
    $graph->add_nodes([$node1, $node2]);
    my $edge = Net::GraphSpace::Edge->new(
        id => '1-2', source => 1, target => 2);
    $graph->add_edge($edge);
    $graph->add_node(Net::GraphSpace::Node->new(id => 3, label => 'C'));

=head1 DESCRIPTION

Represents a graph in GraphSpace.

=head1 ATTRIBUTES

Required:

=over

=item name

=back

Optional:

=over

=item description

Graph description. Can contain some html.

=item tags

An arrayref of tag names.

=back

=head1 METHODS

=head2 add_node($node)

=head2 add_nodes(\@nodes)

=head2 add_edge($edge)

=head2 add_edges(\@edges)

=cut

1;
