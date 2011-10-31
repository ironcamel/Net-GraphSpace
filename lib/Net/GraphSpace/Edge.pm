package Net::GraphSpace::Edge;
use Moose;

with 'Net::GraphSpace::AttributesToJSON';

has id       => (is => 'ro', isa => 'Str', required => 1);
has source   => (is => 'ro', isa => 'Str', required => 1);
has target   => (is => 'ro', isa => 'Str', required => 1);
has label    => (is => 'rw', isa => 'Str');
has popup    => (is => 'rw', isa => 'Str');
has color    => (is => 'rw', isa => 'Str');
has size     => (is => 'rw', isa => 'Num');
has shape    => (is => 'rw', isa => 'Str');
has graph_id => (is => 'rw', isa => 'Int');
has labelFontWeight => (is => 'rw', isa => 'Str');

=head1 SYNOPSIS

    my $node = Net::GraphSpace::Edge->new(
        id       => 'node1-node2', # Required
        source   => 'node1',       # Required
        target   => 'node2',       # Required
        label    => 'edge label',
        popup    => 'stuff that goes in the popup window',
        color    => '#FF0000',
        width    => 5.5,
        graph_id => 2,
        labelFontWeight => 'bold',
    );

=head1 DESCRIPTION

Represents an edge in a GraphSpace graph.
Note that a source and target node are required, even if your edges are
undirected.

=head1 ATTRIBUTES

Required:

=over

=item id

A string id unique amonge all edges.

=item source

The id of the source node.

=item target

The id of the target node.

=back

Optional:

=over

=item label

The node label.

=item popup

Stuff that goes in the popup window.
Currently, this can contain some html.

=item color

The node color in hex format, e.g., '#F00'.

=item width

The width size as a floating point value.

=item graph_id

The integer id of the related graph.

=item labelFontWeight

Can be set to 'normal' or 'bold'.

=back

=head1 SEE ALSO

L<http://cytoscapeweb.cytoscape.org/documentation>

=cut

1;
