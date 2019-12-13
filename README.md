# NAME

Mojolicious::Plugin::CanonicalURL - Ensures canonical URLs via redirection

# STATUS

<div>
    <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-CanonicalURL"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-CanonicalURL.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojolicious-Plugin-CanonicalURL'><img src='https://coveralls.io/repos/github/srchulo/Mojolicious-Plugin-CanonicalURL/badge.svg' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    # Redirects all URLs that have a slash to their no-slash equivalent with a 301 status code.
    $app->plugin('CanonicalURL');

    # Redirects all requests whose paths have no slash to their slash equivalent with a 301 status code.
    $app->plugin('CanonicalURL', { end_with_slash => 1 });

    # Canonicalize any requests whose paths match the regex qr/foo/.
    $app->plugin('CanonicalURL', { should_canonicalize_request => qr/foo/ });

    # Canonicalize only requests with path /foo EXACTLY.
    $app->plugin('CanonicalURL', { should_canonicalize_request => '/foo' });

    # Same as above, but using a subroutine. $_ contains the Mojolicious::Controller for the request.
    use Mojolicious::Plugin::CanonicalURL 'remove_trailing_slashes';
    $app->plugin('CanonicalURL', { should_canonicalize_request => sub { remove_trailing_slashes($_->req->url->path) eq '/foo' } });

    # Same as above, but faster. Code is inlined into the subroutine. This is equally as fast as "should_canonicalize_request => '/foo'" above
    # 'return $next->() unless ' added to the beginning of the string, and ';' added to the end automatically.
    $app->plugin('CanonicalURL', { should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'} } });

    # Same as above, with explicit 'return $next->() unless' at the beginning and ';' at the end.
    $app->plugin('CanonicalURL', { should_canonicalize_request => \q{return $next->() unless remove_trailing_slashes($c->req->url->path) eq '/foo';} } });

    # for multiline code to be inlined, inline_code is recommended instead
    # of should_canonicalize_request
    $app->plugin('CanonicalURL', {
      inline_code => q{
        my $path_no_slashes = remove_trailing_slashes($c->req->url->path);
        return $next->() if $path_no_slashes eq $path1;
        return $next->() if $path_no_slashes eq $path2;
        return $next->() if $path_no_slashes eq $path3;
      },
      # you may pass your own variables for use in inline_code
      captures => {
        '$path1' => \$path1,
        '$path2' => \$path2,
        '$path3' => \$path3,
      },
    });

    # canoncalize all requests that start with /foo
    $app->plugin('CanonicalURL', { should_canonicalize_request => qr{^/foo} });

    # Same as above, but faster because it uses index()
    $app->plugin('CanonicalURL', { should_canonicalize_request => {starts_with => '/foo'} });

    # canoncalize all requests that start with /foo or /bar
    $app->plugin('CanonicalURL', { should_canonicalize_request => [qr{^/foo}, qr{^/bar}] });

    # Same as above, but faster than qr{^/foo} or qr{^/bar} because it uses index()
    $app->plugin('CanonicalURL', { should_canonicalize_request => [{starts_with => '/foo'}, {starts_with => '/bar'}] });

    # Canonicalize all requests except the one with the path /foo
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => '/foo' });

    # All options available to should_canonicalize_request are available to should_not_canonicalize_request.
    # Canonicalize all requests except the one with the path /foo, any request matching qr/bar/, any request
    # starting with /baz, any request with the path /qux/, or any request with the host example.com
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => [
        '/foo',
        qr/bar/,
        {starts_with => '/baz'}
        sub { $_->req->url->path eq '/qux/' },
        \q{$c->req->url->to_abs->host eq 'example.com'},
      ],
    });

    # should_canonicalize_request and should_not_canonicalize_request can be used together
    # All request must start with /foo and must NOT match qr/bar/ to be canonicalized
    # /foo/baz matches
    # /foo/bar does not match
    $app->plugin('CanonicalURL', {
        should_canonicalize_request => {starts_with => '/foo'},
        should_not_canonicalize_request => qr/bar/,
    });

# DESCRIPTION

[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) is a flexible and fast
[Mojlicious::Plugin](https://metacpan.org/pod/Mojlicious::Plugin) to give you control over canonicalizing your URLs.
[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) uses [Sub::Quote](https://metacpan.org/pod/Sub::Quote) to build the subroutine
used as an ["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) hook based on the ["OPTIONS"](#options) you pass
in to make it as fast as possible. [Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) by
default redirects URLs ending with a slash in their path to their non-slash
equivalent. All redirected URLs will have a status code of
[301](https://en.wikipedia.org/wiki/HTTP_301).

["end\_with\_slash"](#end_with_slash) can be set to `1` to instead require that canonicalized
URLs end with a slash.

["should\_canonicalize\_request"](#should_canonicalize_request) and/or ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) can be set to
override the default that all URLs will be canonicalized.

When redirecting to the canonicalized path, all other attributes of the
[Mojo::URL](https://metacpan.org/pod/Mojo::URL) for the request will remain the same (such as query parameters);
only ["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path) will change to the canonicalized form.

[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) will remove multiple trailing slashes and
replace them with one slash if ["end\_with\_slash"](#end_with_slash) is a `true` value, or no slashes if
["end\_with\_slash"](#end_with_slash) is a `false` value.

By default, [Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) only works for dynamic actions that have
methods that are called. This means that, by default, this plugin will not work for [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) routes like this:

    get '/' => {text => 'I ♥ Mojolicious!'};

Or routes in a full app like this:

    sub startup {
      my ($self) = @_;

      my $routes = $self->routes;
      $routes->get('/' => {text => 'I ♥ Mojolicious!'});
    }

See ["canonicalize\_before\_render"](#canonicalize_before_render) to canonicalize non-dynamic actions.

# OPTIONS

## end\_with\_slash

    # Require all canonicalized URLs do not end with a slash. This is the default.
    $app->plugin('CanonicalURL', { end_with_slash => undef });

    # Require all canonicalized URLs end with a slash.
    $app->plugin('CanonicalURL', { end_with_slash => 1 });

Sets whether canonicalized URLs should end with a slash or not. Default is
`undef` (canonicalzed URLs will not end with a slash). This matches up with
how [Mojolicious](https://metacpan.org/pod/Mojolicious) generates ["Named-routes" in Mojolicious::Guides::Routing](https://metacpan.org/pod/Mojolicious::Guides::Routing#Named-routes),
which have no slash at the end. Make sure that if you set [end\_with\_slash](https://metacpan.org/pod/end_with_slash) to
`1` and you used named routes that you keep this in mind so that you do not
redirect anytime a named route URL is used. A role using
["after-methods" in Class::Method::Modifiers](https://metacpan.org/pod/Class::Method::Modifiers#after-methods) may be the correct way to add
trailing slashes by setting the ["trailing\_slash" in Mojo::Path](https://metacpan.org/pod/Mojo::Path#trailing_slash) to `1` on the
[Mojo::URL](https://metacpan.org/pod/Mojo::URL).

If ["end\_with\_slash"](#end_with_slash) is `false`, an exception is made for the root path, `/`,
according to [RFC
2616](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html):

    Note that the absolute path cannot be empty; if none is present in the original URI, it MUST be given as "/" (the server root).

[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) will replace multiple trailing slashes
with one if ["end\_with\_slash"](#end_with_slash) is `true`, or zero if ["end\_with\_slash"](#end_with_slash) is
`false`.

## should\_canonicalize\_request

["should\_canonicalize\_request"](#should_canonicalize_request) is responsible for determining if a given
request should be canonicalized or not. ["should\_canonicalize\_request"](#should_canonicalize_request) can be
several different types of values.

["should\_canonicalize\_request"](#should_canonicalize_request) may be combined with ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request)
to specify conditions that must be met and conditions that must not be met for a request
to be canonicalized.

### SCALAR

If [should\_canonicalize\_request](https://metacpan.org/pod/should_canonicalize_request) is passed a scalar value, it will only canonicalize a reqeust
if its path (["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path)) matches the provided path. Note that all paths are compared without any trailing
slashes, regardless of the value of ["end\_with\_slash"](#end_with_slash). All scalar values should be valid requests paths that start with a `/`.

    # will only canonicalize paths where $c->req->url->path eq '/foo'
    $app->plugin('CanonicalURL', { should_canonicalize_request => '/foo' });

### REGEXP

If ["should\_canonicalize\_request"](#should_canonicalize_request) is passed regex, the regex will be compared
to the path of the request. If the regex does not match against the path, the
request will not be canonicalized.

    # $c->req->url->path =~ qr/foo/ must be true for a request to be canonicalized
    $app->plugin('CanonicalURL', { should_canonicalize_request => qr/foo/ });

### CODE

If ["should\_canonicalize\_request"](#should_canonicalize_request) is passed a subroutine, `$_` will contain
the [Mojolicious::Controller](https://metacpan.org/pod/Mojolicious::Controller) for the current request, and the truth value
returned by the subroutine will determine if the request is canonicalized. If a `true` value
is returned, the request will be canonicalized. If a `false` value is returned, the request
will not be canonicalized.

    # will only canonicalize request if path eq '/foo'
    $app->plugin('CanonicalURL', {
      should_canonicalize_request => sub {
        return remove_trailing_slashes($_->req->url->path) ne '/foo';
      },
    });

### SCALAR REFERENCE

["SCALAR REFERENCE"](#scalar-reference) is similar to ["CODE"](#code), except that the code will be
inlined into the generated method, avoiding the extra subroutine call.

    # 'return $next->() unless ' is added if there is no return at the beginning, and ';' added at the end if it does not exist
    $app->plugin('CanonicalURL', {
      should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'},
    });

`$next` and `$c` from ["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) are available.
"return $next->() unless " is added if the string does not begin with
`return`, and `;` is added to the end if it does not exist. If manually
returning without performing canonicalization, make sure to return
"$next->()".

    return $next->();

You also can have your own variables through ["captures"](#captures):

    my $my_path = '/foo';
    $app->plugin('CanonicalURL', {
      captures => { '$my_path' => \$my_path },
      should_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq $my_path},
    });

But be careful not to use any ["RESERVED VARIABLE NAMES"](#reserved-variable-names).

This is really meant for small one-liners that evaluate to a true/false value. For longer, more custom code, see ["inline\_code"](#inline_code).

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) provides ["remove\_trailing\_slashes"](#remove_trailing_slashes), which can be used in inlined code or
exported.

### HASH

["should\_canonicalize\_request"](#should_canonicalize_request) may be provided a hash reference to specify what path a request must start with
to be canonicalized. The key must be `starts_with`, and the value should be a valid path starting with a slash.

    # all reqeusts must start with '/foo' to be canonicalized
    $app->plugin('CanonicalURL', { should_canonicalize_request => { starts_with => '/foo' } });

In the future, this may allow other keys, like `contains`, which could be a faster form of something like `qr/bar/`.

### ARRAY

["should\_canonicalize\_request"](#should_canonicalize_request) can be passed an array reference with any number of elements as defined
by ["SCALAR"](#scalar), ["REGEXP"](#regexp), ["CODE"](#code), ["SCALAR REFERENCE"](#scalar-reference) and ["HASH"](#hash), and these conditions will be or'ed together, so that a request
will be canonicalized if any of the conditions is true. Note that a [SCALAR REFERENCE](#scalar-reference1) should just be a condition, without
a `return` or trailing `;`.

["captures"](#captures) may be used if a scalar reference is provided in the array.

    # Canonicalize any request whose path equals '/foo', any request whose path matches qr/bar/, any request
    # whose path starts with '/baz', any request with the path '/qux/', or any request that has the host example.com
    $app->plugin('CanonicalURL', { should_canonicalize_request => [
        '/foo',
        qr/bar/,
        {starts_with => '/baz'},
        sub { $_->req->url->path eq '/qux/' },
        \q{$c->req->url->to_abs->host eq 'example.com'},
      ],
    });

## should\_not\_canonicalize\_request

["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) is responsible for determining if a given
request should be canonicalized or not. ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) accepts
the same types of values as ["should\_canonicalize\_request"](#should_canonicalize_request), but handles them oppositely.

["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) may be combined with ["should\_canonicalize\_request"](#should_canonicalize_request)
to specify conditions that must not be met and conditions that must be met for a request
to be canonicalized.

### SCALAR

If [should\_not\_canonicalize\_request](https://metacpan.org/pod/should_not_canonicalize_request) is passed a scalar value, it will only canonicalize a reqeust
if its path (["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path)) does not match the provided path. Note that all paths are compared without any trailing
slashes, regardless of the value of ["end\_with\_slash"](#end_with_slash). All scalar values should be valid requests paths that start with a `/`.

    # will only canonicalize paths where $c->req->url->path ne '/foo'
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => '/foo' });

### REGEXP

If ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) is passed regex, the regex will be compared
to the path of the request. If the regex matches against the path, the
request will not be canonicalized.

    # $c->req->url->path !~ qr/foo/ must be true for a request to be canonicalized
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => qr/foo/ });

### CODE

If ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) is passed a subroutine, `$_` will contain
the [Mojolicious::Controller](https://metacpan.org/pod/Mojolicious::Controller) for the current request, and the truth value
returned by the subroutine will determine if the request is canonicalized. If a `true` value
is returned, the request will not be canonicalized. If a `false` value is returned, the request
will be canonicalized.

    # will not canonicalize request if path eq '/foo'
    $app->plugin('CanonicalURL', {
      should_not_canonicalize_request => sub {
        return remove_trailing_slashes($_->req->url->path) eq '/foo';
      },
    });

### SCALAR REFERENCE

[SCALAR REFERECE](#scalar-reference1) is similar to [CODE](#code1), except that the code will be
inlined into the generated method, avoiding the extra subroutine call.

    # 'return $next->() if ' is added if there is no return at the beginning, and ';' added at the end if it does not exist
    $app->plugin('CanonicalURL', {
      should_not_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq '/foo'},
    });

`$next` and `$c` from ["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) are available.
"return $next->() if " is added if the string does not begin with
`return`, and `;` is added to the end if it does not exist. If manually
returning without performing canonicalization, make sure to return
"$next->()".

    return $next->();

You also can have your own variables through ["captures"](#captures):

    my $my_path = '/foo';
    $app->plugin('CanonicalURL', {
      captures => { '$my_path' => \$my_path },
      should_not_canonicalize_request => \q{remove_trailing_slashes($c->req->url->path) eq $my_path},
    });

But be careful not to use any ["RESERVED VARIABLE NAMES"](#reserved-variable-names).

This is really meant for small one-liners that evaluate to a true/false value. For longer, more custom code, see ["inline\_code"](#inline_code).

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) provides ["remove\_trailing\_slashes"](#remove_trailing_slashes), which can be used in inlined code or
exported.

### HASH

["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) may be provided a hash reference to specify what paths a request must start with
to not be canonicalized. The key must be `starts_with`, and the value should be a valid path starting with a slash.

    # all reqeusts must not start with '/foo' to be canonicalized
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => { starts_with => '/foo' } });

In the future, this may allow other keys, like `contains`, which could be a faster form of something like `qr/bar/`.

### ARRAY

["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) can be passed an array reference with any number of elements as defined
by [SCALAR](#scalar2), [REGEXP](#regexp1), [CODE](#code1), [SCALAR REFERENCE](#scalar-reference1) and [HASH](#hash1), and these conditions will be or'ed together, so that a request
will not be canonicalized if any of the conditions is true. Note that a [SCALAR REFERENCE](#scalar-reference1) should just be a condition, without
a `return` or trailing `;`.

["captures"](#captures) may be used if a scalar reference is provided in the array.

    # Do not canonicalize any request whose path equals '/foo', any request whose path matches qr/bar/, any request
    # whose path starts with '/baz', any request with the path '/qux/', or any request that has the host example.com
    $app->plugin('CanonicalURL', { should_not_canonicalize_request => [
        '/foo',
        qr/bar/,
        {starts_with => '/baz'},
        sub { $_->req->url->path eq '/qux/' },
        \q{$c->req->url->to_abs->host eq 'example.com'},
      ],
    });

## inline\_code

["inline\_code"](#inline_code) allows you to pass in code that will be run right before the code
to canonicalize a request runs, but after any code generated by ["should\_canonicalize\_request"](#should_canonicalize_request) or ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request).
This is meant for larger, more custom code than the scalar inline code
allowed for ["should\_canonicalize\_request"](#should_canonicalize_request) and ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request).

    $app->plugin('CanonicalURL', {
      inline_code => q{
        # custom code
        if (...) {
          $c->app->log("Path is " . $c->req->url->path);
          return $next->() if remove_trailing_slashes($c->req->url->path) eq '/foo';
        }
      },
    });

If ["inline\_code"](#inline_code) is set, ["captures"](#captures) may be used to access your variables inside of the code:

    $app->plugin('CanonicalURL', {
      captures => { '$my_var' => \$my_var },
      inline_code => q{
        if (...) {
          # custom code
          $c->app->log("My var is $my_var");
          return $next->() if $c->req->url->path eq $my_var;
        }
      },
    });

When comparing paths manually, be sure to handle the case where a path may or may not have a slash at the end.
[Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) provides ["remove\_trailing\_slashes"](#remove_trailing_slashes), which can be used in inlined code or
exported.

## captures

    my $skip = {
      '/path_one' => 1,
      '/path_two' => 1,
    };

    $app->plugin('CanonicalURL', {
      captures => { '$skip' => \$skip },
      should_canonicalize_request => \'exists $skip->{remove_trailing_slashes($c->req->url->path)}',
    });

    # same as above using inline_code
    $app->plugin('CanonicalURL', {
      captures => { '$skip' => \$skip },
      inline_code => q{
        if (exists $skip->{$c->req->url->path}) {
          return $next->();
        }
      },
    });

["captures"](#captures) corresponds to captures in [Sub::Quote](https://metacpan.org/pod/Sub::Quote):

    \%captures is a hashref of variables that will be made available to the code.
    The keys should be the full name of the variable to be made available, including the sigil.
    The values should be references to the values. The variables will contain copies of the values.

["captures"](#captures) can only be used when ["should\_canonicalize\_request"](#should_canonicalize_request) or ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) use ["SCALAR REFERENCE"](#scalar-reference) or [SCALAR REFERENCE](#scalar-reference1),
or when a scalar reference is provided in ["ARRAY"](#array) or [ARRAY](#array1) for ["should\_canonicalize\_request"](#should_canonicalize_request) or ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request),
or when ["inline\_code"](#inline_code) is set.

See ["SYNOPSIS" in Sub::Quote](https://metacpan.org/pod/Sub::Quote#SYNOPSIS)'s `Silly::dragon` for an example using captures.

## canonicalize\_before\_render

    # Now the before_render hook will be used to canonicalize requests in addition to the around_action hook.
    $app->plugin('CanonicalURL', {
      canonicalize_before_render => 1,
    });

    # useful for actions defined like this in Mojolicious::Lite which will not trigger the around_action hook
    get '/' => {text => 'I ♥ Mojolicious!'};

    # or actions like this in the full app
    sub startup {
      my ($self) = @_;

      my $routes = $self->routes;
      $routes->get('/' => {text => 'I ♥ Mojolicious!'});
    }

For text routes as shown above, no action is actually called, because the text is stored with the route and
rendered from the string without being wrapped in a subroutine. This means that
requests for these routes cannot be canonicalized using the
["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) hook. When using routes of
this format, ["canonicalize\_before\_render"](#canonicalize_before_render) must be set to `1` so that the
["before\_render" in Mojolicious](https://metacpan.org/pod/Mojolicious#before_render) hook will be used instead to canonicalize these
requests. If a request was already successfully canonicalized (or redirected by other means) in the
["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) hook, then the ["before\_render" in Mojolicious](https://metacpan.org/pod/Mojolicious#before_render) hook
will return early. However, both the ["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) and
["before\_render" in Mojolicious](https://metacpan.org/pod/Mojolicious#before_render) hooks will be called when a request does not need
to be canonicalized, performing the same work twice (the performance of this
shouldn't be a problem, especially for lite apps).

By default, ["canonicalize\_before\_render"](#canonicalize_before_render) is `undef`, meaning that the
["before\_render" in Mojolicious](https://metacpan.org/pod/Mojolicious#before_render) hook is not used to canonicalize requests, only
the ["around\_action" in Mojolicious](https://metacpan.org/pod/Mojolicious#around_action) hook is used.

# EXPORTED

## remove\_trailing\_slashes

Removes all trailing slashes from a path. Accepts a string or a blessed reference that overloads `""`, such as [Mojo::Path](https://metacpan.org/pod/Mojo::Path). This is useful for examining paths.

    # export to use in your code
    use Mojolicious::Plugin::CanonicalURL 'remove_trailing_slashes';
    $app->plugin('CanonicalURL', { should_canonicalize_request => sub { remove_trailing_slashes($_->req->url->path) eq '/foo' } });

    # or use in code that is inlined
    $app->plugin('CanonicalURL', { should_canonicalize_request => \q{remove_trailing_slashes($_->req->url->path) eq '/foo'} });

["remove\_trailing\_slashes"](#remove_trailing_slashes) can be exported or used by inlined code, such as when ["should\_canonicalize\_request"](#should_canonicalize_request) or ["should\_not\_canonicalize\_request"](#should_not_canonicalize_request) use ["SCALAR REFERENCE"](#scalar-reference) or [SCALAR REFERENCE](#scalar-reference1),
or when ["inline\_code"](#inline_code) is set.

# RESERVED VARIABLE NAMES

These are the variable names that [Mojolicious::Plugin::CanonicalURL](https://metacpan.org/pod/Mojolicious::Plugin::CanonicalURL) uses and you should avoid using when declaring your own
variables via ["inline\_code"](#inline_code), ["SCALAR REFERENCE"](#scalar-reference), [SCALAR REFERENCE](#scalar-reference1), or ["captures"](#captures):

- `$c`
- `$next`
- `$_mpcu_path`
- `$_mpcu_path_length`
- `$_mpcu_path_with_no_slashes_at_the_end`
- `$_mpcu_*`

# AUTHOR

Adam Hopkins <srchulo@cpan.org>

# COPYRIGHT

Copyright 2019- Adam Hopkins

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [Mojolicious](https://metacpan.org/pod/Mojolicious)
- [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin)
