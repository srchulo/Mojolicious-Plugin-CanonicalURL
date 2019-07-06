use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;
use Mojo::Util;

lives_ok { plugin 'CanonicalURL' }, 'no config lives';
lives_ok { plugin CanonicalURL => {} }, 'empty hash config lives';

# cannot test throws when config isn't a hashref, because Mojolicious::Plugins::register_plugin wraps arguments in a hashref

throws_ok { plugin CanonicalURL => {should_canonicalize_request => 1, do_not_canonicalize => 1} }
qr/can only set one of should_canonicalize_request or do_not_canonicalize/,
  'setting both should_canonicalize_request and do_not_canonicalize throws';

# test should_canonicalize_request
throws_ok { plugin CanonicalURL => {should_canonicalize_request => {}} }
qr/should_canonicalize_request must be a scalar, a REGEXP reference, a reference to a scalar, or a CODE reference, but was 'HASH'/,
  'should_canonicalize_request passed hashref fails';
throws_ok { plugin CanonicalURL => {should_canonicalize_request => []} }
qr/should_canonicalize_request must be a scalar, a REGEXP reference, a reference to a scalar, or a CODE reference, but was 'ARRAY'/,
  'should_canonicalize_request passed arrayref fails';
lives_ok { plugin CanonicalURL => {should_canonicalize_request => 1} },
  'scalar should_canonicalize_request lives';
lives_ok { plugin CanonicalURL => {should_canonicalize_request => undef} },
  'undef should_canonicalize_request lives';
lives_ok { plugin CanonicalURL => {should_canonicalize_request => qr/bar/} },
  'REGEXP should_canonicalize_request lives';
lives_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()'} },
  'scalar reference should_canonicalize_request lives';
lives_ok {
    plugin CanonicalURL => {
        should_canonicalize_request => sub { }
    }
}, 'CODE reference should_canonicalize_request lives';

# test captures
throws_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()', captures => undef} }
qr/captures must be a HASH reference/,
  'undef captures throws';
throws_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()', captures => 1} }
qr/captures must be a HASH reference/,
  'int captures throws';
throws_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()', captures => 'hi'} }
qr/captures must be a HASH reference/,
  'string captures throws';
throws_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()', captures => []} }
qr/captures must be a HASH reference/,
  'array captures throws';
lives_ok { plugin CanonicalURL => {should_canonicalize_request => \'return $next->()', captures => {}} },
  'hash captures lives';

# test do_not_canonicalize
throws_ok { plugin CanonicalURL => {do_not_canonicalize => undef} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed undef fails';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => ''} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed empty string fails';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => '0'} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed zero string fails';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => 0} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed zero fails';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => 'abc'} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  q{do_not_canonicalize passed string that doesn't begin with a slash fails};
throws_ok { plugin CanonicalURL => {do_not_canonicalize => {}} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed hashref fails';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => 1} }
qr{do_not_canonicalize must be a scalar that evaluates to true and starts with a '/', a REGEXP, or array reference},
  'do_not_canonicalize passed int fails';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => '/path'
    }
}, 'do_not_canonicalize passed string that starts with slash lives';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => qr/bar/
    }
}, 'do_not_canonicalize passed regex lives';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => []
    }
}, 'do_not_canonicalize passed arrayref lives';

# test elements when do_not_canonicalize is array
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [undef]} }
qr/elements of do_not_canonicalize must be a true value/,
  'array do_not_canonicalize does not allow undef elements';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => ['']} }
qr/elements of do_not_canonicalize must be a true value/,
  'array do_not_canonicalize does not allow empty strings elements';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [0]} }
qr/elements of do_not_canonicalize must be a true value/,
  'array do_not_canonicalize does not allow int zero elements';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => ['0']} }
qr/elements of do_not_canonicalize must be a true value/,
  'array do_not_canonicalize does not allow string zero elements';

throws_ok { plugin CanonicalURL => {do_not_canonicalize => [[]]} }
qr/elements of do_not_canonicalize must have a reftype of undef \(scalar\), REGEXP, or HASH but was 'ARRAY'/,
  'arrayref element of do_not_canonicalize throws';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => ['/path']
    }
}, 'do_not_canonicalize passed array with string that starts with slash lives';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => [qr/bar/]
    }
}, 'do_not_canonicalize passed array with regex lives';

# array elements that are scalars and do not begin with a slash throw
throws_ok { plugin CanonicalURL => {do_not_canonicalize => ['noslash']} }
qr{elements of do_not_canonicalize must begin with a '/' when they are scalar},
  'no slash scalar element of do_not_canonicalize throws';

# test hash elements
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{}]} }
qr{must provide key 'starts_with' to hash in do_not_canonicalize},
  'empty hash element of do_not_canonicalize throws';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{starts_with => undef}]} }
qr/value for starts_with must not be undef/,
  'undef starts_with for hash element of do_not_canonicalize throws';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{starts_with => []}]} }
qr/value for starts_with must be a scalar/,
  'array starts_with for hash element of do_not_canonicalize throws';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{starts_with => {}}]} }
qr/value for starts_with must be a scalar/,
  'hash starts_with for hash element of do_not_canonicalize throws';
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{starts_with => 'noslash'}]} }
qr{value for starts_with must begin with a '/'},
  q{scalar that doesn't begin with a '/' for starts_with for hash element of do_not_canonicalize throws};
my $key_value_dump = Mojo::Util::dumper {key => 'value'};
throws_ok { plugin CanonicalURL => {do_not_canonicalize => [{starts_with => '/path', key => 'value'}]} }
qr/unknown keys passed in hash inside of do_not_canonicalize \Q$key_value_dump\E/,
  'extra keys/values for hash element of do_not_canonicalize throws';
lives_ok {
    plugin CanonicalURL => {
        do_not_canonicalize => [{ starts_with => '/path' }]
    }
}, 'do_not_canonicalize passed array with hashref and starts_with path with slash lives';

# test canonicalize_before_render
throws_ok { plugin CanonicalURL => {canonicalize_before_render => []} }
qr/canonicalize_before_render must be a scalar value/,
  'array canonicalize_before_render throws';
throws_ok { plugin CanonicalURL => {canonicalize_before_render => {}} }
qr/canonicalize_before_render must be a scalar value/,
  'hash canonicalize_before_render throws';
lives_ok { plugin CanonicalURL => {canonicalize_before_render => undef} }
  'undef canonicalize_before_render lives';
lives_ok { plugin CanonicalURL => {canonicalize_before_render => 1} }
  '1 canonicalize_before_render lives';

# test that captures only applies when should_canonicalize_request is a scalar reference
throws_ok { plugin CanonicalURL => { should_canonicalize_request => 1, captures => {} } }
qr/captures only applies when should_canonicalize_request is a scalar reference/,
  'scalar should_canonicalize_request with captures throws';
throws_ok { plugin CanonicalURL => { should_canonicalize_request => qr/bar/, captures => {} } }
qr/captures only applies when should_canonicalize_request is a scalar reference/,
  'REGEXP should_canonicalize_request with captures throws';
throws_ok { plugin CanonicalURL => { should_canonicalize_request => sub {}, captures => {} } }
qr/captures only applies when should_canonicalize_request is a scalar reference/,
  'CODE should_canonicalize_request with captures throws';
throws_ok { plugin CanonicalURL => { do_not_canonicalize => '/path', captures => {} } }
qr/captures only applies when should_canonicalize_request is a scalar reference/,
  'string do_not_canonicalize with captures throws';

# test end_with_slash must be a scalar value
throws_ok { plugin CanonicalURL => {end_with_slash => {}} }
qr/end_with_slash must be a scalar value/,
  'hashref end_with_slash throws';
throws_ok { plugin CanonicalURL => {end_with_slash => []} }
qr/end_with_slash must be a scalar value/,
  'arrayref end_with_slash throws';
lives_ok { plugin CanonicalURL => {end_with_slash => undef} }
  'undef end_with_slash lives';
lives_ok { plugin CanonicalURL => {end_with_slash => 1} }
  '1 end_with_slash lives';
lives_ok { plugin CanonicalURL => {end_with_slash => 'string'} }
  'string end_with_slash lives';

# test unknown keys not allowed
$key_value_dump = Mojo::Util::dumper {key => 'value'};
throws_ok { plugin CanonicalURL => {key => 'value'} }
qr/unknown keys passed in config: \Q$key_value_dump\E/,
  'extra keys/values for config throws';
throws_ok { plugin CanonicalURL => {end_with_slash => 1, key => 'value'} }
qr/unknown keys passed in config: \Q$key_value_dump\E/,
  'extra keys/values for config with legitimate values throws';

done_testing;
