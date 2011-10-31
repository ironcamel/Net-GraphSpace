package Net::GraphSpace::Types;
use Moose::Util::TypeConstraints;

subtype 'LabelFontWeight'
    => as 'Str'
    => where { $_ ~~ [qw(normal bold)] }
    => message { "$_ is not a valid LabelFontWeight ('bold', 'normal')" };

class_type 'HTTP::Response';

1;
