use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Test::Warn;

use FindBin;
use lib "$FindBin::Bin/lib";

# test string do not canonicalize for exact match
my $t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => '/dont_canonicalize/'});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');

# test that trailing slash doesn't matter
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => '/dont_canonicalize'});
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');

# test regex
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => qr/dont/});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize_plz/')->status_is(200)->content_is('dont canonicalize plz!');

# test empty array warns and nothing is canonicalized
$t = Test::Mojo->new('MojoliciousTest');
warning_like { $t->app->plugin(CanonicalURL => {do_not_canonicalize => []}) }
qr/do_not_canonicalize is an empty array and requests will never be canonicalized/,
  'empty array warns';
$t->get_ok('/canonicalize_plz')->status_is(200)->content_is('canonicalize plz!');
$t->get_ok('/canonicalize_plz/')->status_is(200)->content_is('canonicalize plz!');
$t->get_ok('/dont_canonicalize')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize_plz')->status_is(200)->content_is('dont canonicalize plz!');
$t->get_ok('/dont_canonicalize_plz/')->status_is(200)->content_is('dont canonicalize plz!');

# test string in array do not canonicalize for exact match
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => ['/dont_canonicalize/']});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');

# test that trailing slash in string in array doesn't matter
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => ['/dont_canonicalize']});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');

# test regex in array
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => [qr/dont/]});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize_plz/')->status_is(200)->content_is('dont canonicalize plz!');

# test starts_with in array
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(CanonicalURL => {do_not_canonicalize => [{starts_with => '/dont'}]});
$t->get_ok('/canonicalize_plz/')->status_is(301)->header_is(Location => '/canonicalize_plz');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize_plz/')->status_is(200)->content_is('dont canonicalize plz!');

# test all three types in array
$t = Test::Mojo->new('MojoliciousTest');
$t->app->plugin(
    CanonicalURL => {
        do_not_canonicalize =>
          [qr#^/can#, {starts_with => '/dont_canonicalize_'}, '/dont_canonicalize']});
$t->get_ok('/canonicalize_plz/')->status_is(200)->content_is('canonicalize plz!');
$t->get_ok('/dont_canonicalize/')->status_is(200)->content_is('dont canonicalize');
$t->get_ok('/dont_canonicalize_plz/')->status_is(200)->content_is('dont canonicalize plz!');

done_testing;
