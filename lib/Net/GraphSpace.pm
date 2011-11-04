package Net::GraphSpace;
use Moose;
use MooseX::Method::Signatures;

# VERSION

use JSON qw(decode_json);
use LWP::UserAgent;
use Net::GraphSpace::Node;
use Net::GraphSpace::Edge;
use Net::GraphSpace::Graph;

has user     => (is => 'ro', isa => 'Str', required => 1);
has password => (is => 'ro', isa => 'Str', required => 1);
has host     => (is => 'ro', isa => 'Str', required => 1);
has port     => (is => 'ro', isa => 'Str', default => 80);
has _ua      => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new();
        $ua->credentials(sprintf('%s:%d', $self->host, $self->port),
            'restricted area', $self->user, $self->password); 
        return $ua;
    },
);
has _json => (
    is      => 'ro',
    isa     => 'JSON',
    lazy    => 1,
    default => sub { JSON->new->pretty->convert_blessed->utf8 },
);

method to_json($x) { $self->_json->encode($x) }

method gen_url($path) {
    return sprintf('http://%s:%d%s', $self->host, $self->port, $path);
}

method add_graph(Net::GraphSpace::Graph $graph) {
    my $url = $self->gen_url('/api/graphs');
    my $res = $self->_ua->post($url, Content => $self->to_json($graph));
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

method get_graph(Int $graph_id) {
    my $url = $self->gen_url("/api/graphs/$graph_id");
    my $res = $self->_ua->get($url);
    die msg_from_res($res) unless $res->is_success;
    return Net::GraphSpace::Graph->new_from_http_response($res);
}

method update_graph(Int $graph_id, Net::GraphSpace::Graph $graph) {
    my $url = $self->gen_url("/api/graphs/$graph_id");
    my $req = HTTP::Request->new(PUT => $url, [], $self->to_json($graph));
    my $res = $self->_ua->request($req);
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

method delete_graph(Int $graph_id) {
    my $url = $self->gen_url("/api/graphs/$graph_id");
    my $req = HTTP::Request->new(DELETE => $url);
    my $res = $self->_ua->request($req);
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

sub msg_from_res {
    my ($res) = @_;
    return $res->status_line . "\n" . $res->content;
}

# ABSTRACT: API bindings for GraphSpace

=head1 SYNOPSIS

    use Net::GraphSpace;
    use JSON qw(decode_json);

    my $client = Net::GraphSpace->new(
        user     => 'bob',
        password => 'secret',
        host     => 'graphspace.org'
    );
    my $graph = Net::GraphSpace::Graph->new(name => 'yeast ppi');
    my $node1 = Net::GraphSpace::Node->new(id => 'node-a', label => 'A');
    my $node2 = Net::GraphSpace::Node->new(id => 'node-b', label => 'B');
    my $edge = Net::GraphSpace::Edge->new(
        id => 'a-b', source => 'node-a', target => 'node-b');
    $graph->add_nodes([$node1, $node2]);
    $graph->add_edge($edge);
    $graph->add_node(Net::GraphSpace::Node->new(id => 3, label => 'C'));

    # Upload graph to server
    my $data = $client->add_graph($graph);
    my $graph_id = $data->{id};
    my $url = $data->{url};
    print "Your graph (id: $graph_id) can be viewed at $url\n";

    # Get and update a graph
    $graph = $clent->get_graph($graph_id);
    $graph->tags(['foo', 'bar']);
    $client->update_graph($graph_id, $graph);

    # Delete a graph
    $client->delete_graph($graph_id);

=head1 DESCRIPTION

Net::GraphSpace provides bindings for the GraphSpace API.

=head1 ATTRIBUTES

Required:

=over

=item user

=item password

=item host

=back

Optional:

=over

=item port

Defaults to 80.

=back

=head1 METHODS

=head2 new(%params)

Takes key/value arguments corresponding to the attributes above.

=head2 add_graph($graph)

Takes a Net::GraphSpace::Graph object and uploads it.
Returns a hashref of the form:

    {
        id => 1,
        url => 'http://...',
    }

The url is the location where the graph can be viewed.

=head2 get_graph($graph_id)

Returns a Net::GraphSpace::Graph object for the given $graph_id.

=head2 update_graph($graph_id, $graph)

Updates the graph on the server with id $graph_id by replacing it with $graph.

=head2 delete_graph($graph_id)

=cut

1;
