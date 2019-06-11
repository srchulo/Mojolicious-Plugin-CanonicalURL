use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

get '/found' => sub {
    shift->render(text => 'I exist!');
};

plugin CanonicalURL => { end_with_slash => 1 };

my $t = Test::Mojo->new;

# make sure that a slash is required
$t->get_ok('/found/')->status_is(200)->content_is('I exist!');
$t->get_ok('/found')->status_is(301)->header_is(Location => '/found/');

$t->get_ok('/static.txt')->status_is(200)->content_is("hi\n");

done_testing;
