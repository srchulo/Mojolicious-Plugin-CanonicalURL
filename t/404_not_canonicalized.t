use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

get '/found' => sub {
    shift->render(text => 'I exist!');
};

plugin 'CanonicalURL';

my $t = Test::Mojo->new;
$t->get_ok('/found')->status_is(200)->content_is('I exist!');
$t->get_ok('/found/')->status_is(301)->header_is(Location => '/found');

# 404 should not be redirected
$t->get_ok('/not_found/')->status_is(404);

done_testing;
