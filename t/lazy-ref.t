use Mojo::Base -strict;
use Test::More;
use JSON::Validator;
use Mojo::Util qw( slurp spurt );

my $file = File::Spec->catfile(File::Basename::dirname(__FILE__), 'spec', 'lazy-ref.json');
my $validator = JSON::Validator->new->schema($file);

is_deeply $validator->schema->get('/properties/entry/required'), ['body', 'title'], 'loaded entry.json';

done_testing;
