use Mojo::Base -strict;
use Test::More;
use JSON::Validator;

my $validator = JSON::Validator->new;
my ($schema, @errors);

{
  $schema = {type => 'object'};
  @errors = $validator->validate({mynumber => 1}, $schema);
  is "@errors", "", "object";
  @errors = $validator->validate([1], $schema);
  is "@errors", "/: Expected object - got array.", "got array";
}

{
  $schema->{properties} = {
    number      => {type => "number"},
    street_name => {type => "string"},
    street_type => {type => "string", enum => ["Street", "Avenue", "Boulevard"]}
  };
  local $schema->{patternProperties} = {"^S_" => {type => "string"}, "^I_" => {type => "integer"}};

  @errors
    = $validator->validate({number => 1600, street_name => "Pennsylvania", street_type => "Avenue"},
    $schema);
  is "@errors", "", "object with properties";
  @errors = $validator->validate(
    {number => "1600", street_name => "Pennsylvania", street_type => "Avenue"}, $schema);
  is "@errors", "/number: Expected number - got string.", "object with invalid number";
  @errors = $validator->validate({number => 1600, street_name => "Pennsylvania"}, $schema);
  is "@errors", "", "object with missing properties";
  @errors
    = $validator->validate(
    {number => 1600, street_name => "Pennsylvania", street_type => "Avenue", direction => "NW"},
    $schema);
  is "@errors", "", "object with additional properties";

  @errors = $validator->validate({"S_25" => "This is a string", "I_0" => 42}, $schema);
  is "@errors", "", "S_25 I_0";
  @errors = $validator->validate({"S_0" => 42}, $schema);
  is "@errors", "/S_0: Expected string - got number.", "S_0";
}

{
  local $schema->{additionalProperties} = 0;
  @errors
    = $validator->validate(
    {number => 1600, street_name => "Pennsylvania", street_type => "Avenue", direction => "NW"},
    $schema);
  is "@errors", "/: Properties not allowed: direction (wanted Object[number?:number, street_name?:string, street_type?:string]).", "additionalProperties=0";

  $schema->{additionalProperties} = {type => "string"};
  @errors
    = $validator->validate(
    {number => 1600, street_name => "Pennsylvania", street_type => "Avenue", direction => "NW"},
    $schema);
  is "@errors", "", "additionalProperties=object";
}

{
  local $schema->{required} = ["number", "street_name"];
  @errors = $validator->validate({number => 1600, street_type => "Avenue"}, $schema);
  is "@errors", "/street_name: Missing property (wanted Object[number:number, street_name:string, street_type?:string]).", "object with required";
}

{
  $schema = {type => 'object', minProperties => 1};
  @errors = $validator->validate({}, $schema);
  is "@errors", "/: Not enough properties: 0/1.", "not enough properties 0/1";
  $schema = {type => 'object', minProperties => 2, maxProperties => 3};
  @errors = $validator->validate({a => 1}, $schema);
  is "@errors", "/: Not enough properties: 1/2.", "not enough properties 1/2";
  @errors = $validator->validate({a => 1, b => 2}, $schema);
  is "@errors", "", "object with required";
  @errors = $validator->validate({a => 1, b => 2, c => 3, d => 4}, $schema);
  is "@errors", "/: Too many properties: 4/3.", "too many properties";
}

{
  local $TODO = 'Add support for dependencies';
  $schema = {
    type       => "object",
    properties => {
      name            => {type => "string"},
      credit_card     => {type => "number"},
      billing_address => {type => "string"}
    },
    required     => ["name"],
    dependencies => {credit_card => ["billing_address"]}
  };

  @errors = $validator->validate({name => "John Doe", credit_card => 5555555555555555}, $schema);
  is "@errors", "/credit_card: Missing billing_address.", "credit_card";
}

sub TO_JSON { return {age => shift->{age}} }
my $obj = bless {age => 'not_a_string'}, 'main';
@errors = $validator->validate($obj, {properties => {age => {type => 'integer'}}});
is "@errors", "/age: Expected integer - got string.", "age is not a string";

done_testing;
