package Net::GraphSpace;
use Moose;

# VERSION

use v5.10;
use JSON qw(decode_json);
use LWP::UserAgent;
use Net::GraphSpace::Edge;
use Net::GraphSpace::Graph;
use Net::GraphSpace::Node;

has user     => (is => 'ro', isa => 'Str', required => 1);
has password => (is => 'ro', isa => 'Str', required => 1);
has host     => (is => 'ro', isa => 'Str', default => 'graphspace.org');
has port     => (is => 'ro', isa => 'Str', default => 80);
has prefix   => (is => 'ro', isa => 'Str', default => '');
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
    default => sub { JSON->new->convert_blessed->utf8 },
);

sub to_json { $_[0]->_json->encode($_[1]) }

sub gen_url {
    my ($self, $path) = @_;
    my ($host, $port, $prefix) = ($self->host, $self->port, $self->prefix);
    s{^/}{}, s{/$}{} foreach ($prefix, $path);
    return "http://$host:$port/$prefix/$path";
}

sub add_graph {
    my ($self, $graph, $graph_id, %args) = @_;
    my $check = $args{check} // 1;

    my $user = $self->user;
    my $res;
    if (defined $graph_id) {
        if ($check) {
            die "ERROR: Graph [$graph_id] already exists"
                if $self->get_graph($graph_id);
        }
        my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
        my $req = HTTP::Request->new(PUT => $url, [], $self->to_json($graph));
        $res = $self->_ua->request($req);
    } else {
        my $url = $self->gen_url("/api/users/$user/graphs");
        $res = $self->_ua->post($url, Content => $self->to_json($graph));
    }
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

sub get_graph {
    my ($self, $graph_id) = @_;

    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
    my $res = $self->_ua->get($url);
    return undef if $res->code == 404;
    die msg_from_res($res) unless $res->is_success;
    return Net::GraphSpace::Graph->new_from_http_response($res);
}

sub update_graph {
    my ($self, $graph, $graph_id) = @_;

    my $user = $self->user;
    my $url = $self->gen_url("/api/users/$user/graphs/$graph_id");
    my $req = HTTP::Request->new(PUT => $url, [], $self->to_json($graph));
    my $res = $self->_ua->request($req);
    die msg_from_res($res) unless $res->is_success;
    return decode_json($res->content);
}

sub delete_graph {
    my ($self, $graph_id) = @_;

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
    my $data = $client->add_graph($graph, $graph_id);
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
    $client->update_graph($graph, $graph_id);

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

=back

Optional:

=over

=item host

Defaults to 'graphspace.org'.

=item port

Defaults to 80.

=item prefix

Defaults to ''.
Set this if GraphSpace is not hosted at the root of your server.
For example, if GraphSpace is hosted at http://myserver.com/gs,
then set C<prefix =E<gt> '/gs'>.

=back

=head1 METHODS

=head2 new

    $client = Net::GraphSpace->new(user => 'bob', password => 'secret');

Takes key/value arguments corresponding to the attributes above.

=head2 get_graph

    $graph = $clent->get_graph($graph_id)

Returns a Net::GraphSpace::Graph object for the given $graph_id.
Returns undef if the graph could not be found.

=head2 add_graph

    $data = $client->add_graph($graph);
    $data = $client->add_graph($graph, $graph_id);
    $data = $client->add_graph($graph, $graph_id, check => 0);

Takes a Net::GraphSpace::Graph object and uploads it.
If $graph_id is not provided, an id is autogenerated for you by the server.
An optional named paramter $check defaults to 1.
This means that an extra check is made to see if the graph with the given
$graph_id already exists on the server.
An exception is thrown if it is found.
Set $check => 0 if you don't want this check.
This will result in greater efficiency, since one less http request is made to
the server.
Also, if the graph already exists, it will get overwritten as if update_graph() was called.
Returns a hashref of the form:

    {
        id => 1,
        url => 'http://...',
    }

The url is the location where the graph can be viewed.
Dies on server error.

=head2 update_graph

    $data = $client->update_graph($graph, $graph_id);

Updates the graph on the server with id $graph_id.
Returns a hashref just like add_graph().
Dies on server error.

=head2 delete_graph($graph_id)

    $success = $client->delete_graph($graph, $graph_id);

Deletes the graph with id $graph_id.
Returns a true value on success.
Dies on failure or if the graph didn't exist.

=head1 SEE ALSO

=over

=item L<http://graphspace.org>

=back

=cut

1;
