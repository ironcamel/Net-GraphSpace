package Net::GraphSpace::Node;
use Moose;

use Net::GraphSpace::Types;

with 'Net::GraphSpace::AttributesToJSON';

has id       => (is => 'ro', isa => 'Str', required => 1);
has label    => (is => 'rw', isa => 'Str');
has popup    => (is => 'rw', isa => 'Str');
has color    => (is => 'rw', isa => 'Str');
has size     => (is => 'rw', isa => 'Num');
has shape    => (is => 'rw', isa => 'Str');
has graph_id => (is => 'rw', isa => 'Int');
has labelFontWeight => (is => 'rw', isa => 'LabelFontWeight');

=head1 SYNOPSIS

    my $node = Net::GraphSpace::Node->new(
        id       => 'node-a', # Required
        label    => 'Node A',
        popup    => 'stuff that goes in the popup window',
        color    => '#FF0000',
        size     => 10.5,
        shape    => 'RECTANGLE',
        graph_id => 2,
        labelFontWeight => 'bold',
    );

=head1 DESCRIPTION

Represents a node in a GraphSpace graph.

=head1 ATTRIBUTES

Required:

=over

=item id

A string id unique amonge all nodes.

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

=item size

The node size as a floating point value.

=item shape   

The shape of the node.
See L<http://cytoscapeweb.cytoscape.org/documentation/shapes>
for possible values.

=item graph_id

The integer id of the related graph.

=item labelFontWeight

Can be set to 'normal' or 'bold'.

=back

=head1 SEE ALSO

L<http://cytoscapeweb.cytoscape.org/documentation>

=cut

1;
