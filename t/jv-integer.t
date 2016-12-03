use Mojo::Base -strict;
use Test::More;
use JSON::Validator;

my $validator = JSON::Validator->new;
my $schema
  = {type => 'object', properties => {mynumber => {type => 'integer', minimum => 1, maximum => 4}}};

my @errors = $validator->validate({mynumber => 1}, $schema);
is "@errors", "", "min";

@errors = $validator->validate({mynumber => 4}, $schema);
is "@errors", "", "max";

@errors = $validator->validate({mynumber => 2}, $schema);
is "@errors", "", "in the middle";

@errors = $validator->validate({mynumber => 0}, $schema);
is "@errors", "/mynumber: 0 < minimum(1).", 'too small';

@errors = $validator->validate({mynumber => -1}, $schema);
is "@errors", "/mynumber: -1 < minimum(1).", 'too small and neg';

@errors = $validator->validate({mynumber => 5}, $schema);
is "@errors", "/mynumber: 5 > maximum(4).", "too big";

@errors = $validator->validate({mynumber => "2"}, $schema);
is "@errors", "/mynumber: Expected integer - got string.", "a string";

$schema->{properties}{mynumber}{multipleOf} = 2;
@errors = $validator->validate({mynumber => 3}, $schema);
is "@errors", "/mynumber: Not multiple of 2.", "multipleOf";

$validator->coerce(numbers => 1);
@errors = $validator->validate({mynumber => "2"}, $schema);
is "@errors", "", "coerced string into integer";

@errors = $validator->validate({mynumber => "2xyz"}, $schema);
is "@errors", "/mynumber: Expected integer - got string.", "a string";

$schema->{properties}{mynumber}{minimum} = -3;
@errors = $validator->validate({mynumber => "-2"}, $schema);
is "@errors", "", "coerced negative integer";

done_testing;
