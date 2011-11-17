package Net::GraphSpace;
use Moose;
use MooseX::Method::Signatures;

# VERSION

use JSON qw(decode_json);
use LWP::UserAgent;
use Net::GraphSpace::Edge;
use Net::GraphSpace::Graph;
use Net::GraphSpace::Node;

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
    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs");
    my $res = $self->_ua->post($url, Content => $self->to_json($graph));
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

method get_graph(Str $graph_id) {
    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
    my $res = $self->_ua->get($url);
    #die msg_from_res($res) unless $res->is_success;
    return undef unless $res->is_success;
    return Net::GraphSpace::Graph->new_from_http_response($res);
}

method set_graph(Net::GraphSpace::Graph $graph, Str $graph_id) {
    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
    my $req = HTTP::Request->new(PUT => $url, [], $self->to_json($graph));
    my $res = $self->_ua->request($req);
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

method delete_graph(Str $graph_id) {
    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
    my $req = HTTP::Request->new(DELETE => $url);
    my $res = $self->_ua->request($req);
    die msg_from_res($res) unless $res->is_success;
    return 1;
}

sub msg_from_res {
    my ($res) = @_;
    return $res->status_line . "\n" . $res->content;
}

# ABSTRACT: API bindings for GraphSpace

=head1 SYNOPSIS

    use Net::GraphSpace;
    use JSON qw(decode_json);
    use Try::Tiny;

    my $client = Net::GraphSpace->new(
        user     => 'bob',
        password => 'secret',
        host     => 'graphspace.org'
    );
    my $graph = Net::GraphSpace::Graph->new(description => 'yeast ppi');
    my $node1 = Net::GraphSpace::Node->new(id => 'node-a', label => 'A');
    my $node2 = Net::GraphSpace::Node->new(id => 'node-b', label => 'B');
    my $edge = Net::GraphSpace::Edge->new(
        id => 'a-b', source => 'node-a', target => 'node-b');
    $graph->add_nodes([$node1, $node2]);
    $graph->add_edge($edge);
    $graph->add_node(Net::GraphSpace::Node->new(id => 3, label => 'C'));

    # Upload graph to server and set the graph id
    my $graph_id = 'graph-id-1';
    my $data = $client->set_graph($graph, $graph_id);
    my $url = $data->{url};

    # Upload graph to server and have server autogenerate the graph id
    $data = $client->add_graph($graph);
    $graph_id = $data->{id};
    $url = $data->{url};
    print "Your graph (id: $graph_id) can be viewed at $url\n";

    # Get and update a graph
    $graph = $clent->get_graph($graph_id)
        or die "Could not find graph $graph_id";
    $graph->tags(['foo', 'bar']);
    $client->set_graph($graph, $graph_id);

    # Delete a graph
    try {
        $client->delete_graph($graph_id);
        print "Deleted graph $graph_id: $_\n";
    } catch {
        print "Could not delete graph $graph_id: $_\n";
    };

=head1 DESCRIPTION

Net::GraphSpace provides bindings for the GraphSpace API.
GraphSpace is a web based graph/network visualization tool and data store.
See L<http://graphspace.org> for more information.

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

=head2 get_graph($graph_id)

Returns a Net::GraphSpace::Graph object for the given $graph_id.
Returns undef if the graph could not be found.

=head2 set_graph($graph, $graph_id)

Creates or updates the graph on the server with id $graph_id.
Returns a hashref just like add_graph().
Dies on server error.

=head2 add_graph($graph)

Takes a Net::GraphSpace::Graph object and uploads it.
Use this method only if you don't care what id is assigned to your graph.
Otherwise, use set_graph to create your graph.
Returns a hashref of the form:

    {
        id => 1,
        url => 'http://...',
    }

The url is the location where the graph can be viewed.
Dies on server error.

=head2 delete_graph($graph_id)

Deletes the graph with id $graph_id.
Returns a true value on success.
Dies on failure or if the graph didn't exist.

=head1 SEE ALSO

=over

=item L<http://graphspace.org>

=back

=cut

1;
