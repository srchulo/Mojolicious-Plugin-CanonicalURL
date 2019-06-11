requires 'perl', '5.010001';

requires 'Mojolicious';
requires 'Sub::Quote';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Exception';
    requires 'Test::Warn';
};
