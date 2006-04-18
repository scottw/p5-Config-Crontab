use Test;
use blib;
BEGIN { plan tests => 67 };
use Config::Crontab;
ok(1);

## FIXME: add some space tests (as per crontab(5))

my $env;

ok( $env = new Config::Crontab::Env );
ok( $env->dump, '' );
undef $env;

ok( $env = new Config::Crontab::Env( -name  => 'MAILTO',
				     -value => 'scott@perlcode.org' ) );
ok( $env->dump, 'MAILTO=scott@perlcode.org' );
undef $env;

ok( $env = new Config::Crontab::Env( -value => 'scott@perlcode.org' ) );
ok( $env->dump, '' );
ok( $env->name('MAILTO'), 'MAILTO' );
ok( $env->dump, 'MAILTO=scott@perlcode.org' );
undef $env;

ok( $env = new Config::Crontab::Env( -name => 'MAILTO' ) );
ok( $env->dump, 'MAILTO=' );
ok( $env->value('joe@schmoe.org'), 'joe@schmoe.org' );
ok( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;

ok( $env = new Config::Crontab::Env );
ok( $env->dump, '' );
ok( $env->name('MAILTO'), 'MAILTO' );
ok( $env->dump, 'MAILTO=' );
ok( $env->value('foo@bar.baz'), 'foo@bar.baz' );
ok( $env->dump, 'MAILTO=foo@bar.baz');
ok( $env->value(undef), '' );
ok( $env->dump, 'MAILTO=' );
ok( $env->value('bar@baz.blech'), 'bar@baz.blech');
ok( $env->dump, 'MAILTO=bar@baz.blech');
ok( $env->name(undef), '' );
ok( $env->dump, '' );
undef $env;

## test some quoting issues
ok( $env = new Config::Crontab::Env( -name   => 'MAILTO',
				     -value  => 'joe@schmoe.org', ) );
ok( $env->dump, 'MAILTO=joe@schmoe.org' );
ok( $env->value(q!"Scott Wiersdorf" <scott@perlcode.org>!), '"Scott Wiersdorf" <scott@perlcode.org>' );
ok( $env->dump, 'MAILTO="Scott Wiersdorf" <scott@perlcode.org>' );
undef $env;

## test the 'active' method/attribute
ok( $env = new Config::Crontab::Env( -name   => 'MAILTO',
				     -value  => 'joe@schmoe.org',
				     -active => 0 ) );
ok( $env->dump, '#MAILTO=joe@schmoe.org' );
ok( $env->active(1) );
ok( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;

ok( $env = new Config::Crontab::Env );
ok( $env->dump, '' );
ok( $env->name('MAILTO'), 'MAILTO' );
ok( $env->value('foo@bar.org'), 'foo@bar.org' );
ok( $env->dump, 'MAILTO=foo@bar.org' );
ok( $env->active(0), 0 );
ok( $env->dump, '#MAILTO=foo@bar.org' );
ok( $env->value(undef), '' );
ok( $env->dump, '#MAILTO=' );
ok( $env->active(1) );
ok( $env->dump, 'MAILTO=' );
undef $env;

## test the parse constructor
ok( $env = new Config::Crontab::Env(-data => 'MAILTO=joe@schmoe.org') );
ok( $env->dump, 'MAILTO=joe@schmoe.org' );
ok( $env->active );
ok( $env->name, 'MAILTO' );
ok( $env->value, 'joe@schmoe.org' );
undef $env;

## -active is ignored because of -data
ok( $env = new Config::Crontab::Env( -active => 0,
				     -data   => 'MAILTO=foo@bar.com') );
ok( $env->dump, 'MAILTO=foo@bar.com' );
undef $env;

ok( $env = new Config::Crontab::Env( -data => 'MAILTO=' ) );
ok( $env->dump, 'MAILTO=' );
undef $env;

## garbage in constructor should return undef
ok( ! defined($env = new Config::Crontab::Env( -data => 'garbage' )) );
undef $env;

## newline in constructor
ok( $env = new Config::Crontab::Env( -data => "MAILTO=foo\@bar.com\n" ) );
ok( $env->data, 'MAILTO=foo@bar.com' );
ok( $env->value, 'foo@bar.com' );
undef $env;

## newline in data
ok( $env = new Config::Crontab::Env );
ok( $env->data("MAILTO=foo\@bar.com\n"), 'MAILTO=foo@bar.com' );
ok( $env->value, 'foo@bar.com' );
ok( $env->dump, 'MAILTO=foo@bar.com' );
undef $env;

## use the data method
ok( $env = new Config::Crontab::Env );
ok( $env->dump, '' );
ok( $env->data( 'MAILTO = joe@schmoe.org' ), 'MAILTO=joe@schmoe.org' );
ok( $env->name, 'MAILTO' );
ok( $env->value, 'joe@schmoe.org' );
ok( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;
