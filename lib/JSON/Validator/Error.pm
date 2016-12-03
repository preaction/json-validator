package JSON::Validator::Error;
use Mojo::Base -base;
use List::Util qw( any );

use overload
  q("")    => sub { $_[0]->{path} . ': ' . $_[0]->{message} . ( $_[0]->{rule} ? " (wanted $_[0]->{rule})." : "." ) },
  bool     => sub {1},
  fallback => 1;

sub new {
  my $self = bless {}, shift;
  @$self{qw(path message rule)} = ($_[0] || '/', $_[1] || '', $_[2] ? _rule_desc( $_[2] ) : '');
  $self;
}

sub message { shift->{message} }
sub path    { shift->{path} }
sub rule    { shift->{rule} }
sub _rule_desc {
  my ( $rule ) = @_;
  if ( ref $rule eq 'ARRAY' ) {
    my $inner_rules = join( ', ', map { _rule_desc( $_ ) } @$rule );
    return '' unless $inner_rules;
    return '[' . $inner_rules . ']';
  }
  elsif ( $rule->{title} ) {
    return '{' . $rule->{title} . '}';
  }
  elsif ( $rule->{properties}{'$ref'} ) {
    return '{$REF}',
  }
  elsif ( $rule->{type} eq 'object' ) {
    my %required = map { $_ => 1 } @{ $rule->{required} };
    my @required = sort keys %required;
    my @optional = sort grep { !$required{ $_ } } keys %{ $rule->{properties} };
    return '' unless @required || @optional;
    return 'Object[' . join( ", ", (map { "$_:" . ( $rule->{properties}{$_}{type} // "{ANY}" ) } @required ), map { "$_?:" . ( $rule->{properties}{$_}{type} // "{ANY}" ) } @optional ) . ']';
  }
  return;
  return '{' . ucfirst $rule->{type} . '}';
}
sub TO_JSON { {message => $_[0]->{message}, path => $_[0]->{path}, rule => $_[0]->{rule}} }

1;

=encoding utf8

=head1 NAME

JSON::Validator::Error - JSON::Validator error object

=head1 SYNOPSIS

  use JSON::Validator::Error;
  my $err = JSON::Validator::Error->new($path, $message);

=head1 DESCRIPTION

L<JSON::Validator::Error> is a class representing validation errors from
L<JSON::Validator>.

=head1 ATTRIBUTES

=head2 message

  $str = $self->message;

A human readable description of the error. Defaults to empty string.

=head2 path

  $str = $self->path;

A JSON pointer to where the error occurred. Defaults to "/".

=head2 rule

  $str = $self->rule;

A description of the rule that we attempted to match. Defaults to empty string.

=head1 METHODS

=head2 new

  $self = JSON::Validator::Error->new($path, $message);

Object constructor.

=head1 SEE ALSO

L<JSON::Validator>.

=cut
