package MojoliciousTest;
use Mojo::Base 'Mojolicious';

sub startup {
    my ($self) = @_;
    
    my $r = $self->routes;
    
    $r->get('/canonicalize_plz' => sub { shift->render(text => 'canonicalize plz!'); });
    $r->get('/dont_canonicalize/' => sub { shift->render(text => 'dont canonicalize'); });
    $r->get('/dont_canonicalize_plz/' => sub { shift->render(text => 'dont canonicalize plz!'); });
}
 
1;
