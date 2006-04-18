use Test;
use blib;
BEGIN { plan tests => 29 };
use Config::Crontab;
ok(1);

my $comment;

ok( $comment = new Config::Crontab::Comment );
ok( $comment->data, '' );
ok( $comment->dump, '' );
undef $comment;

ok( $comment = new Config::Crontab::Comment( -data => undef ) );
ok( $comment->data, '' );
ok( $comment->dump, '' );
undef $comment;

ok( $comment = new Config::Crontab::Comment( -data => '' ) );
ok( $comment->data, '' );
ok( $comment->dump, '' );
undef $comment;

ok( $comment = new Config::Crontab::Comment );
ok( $comment->dump, '' );
ok( $comment->data, '' );

ok( $comment->data('## testing'), '## testing' );
ok( $comment->data, '## testing' );
ok( $comment->dump, '## testing' );
undef $comment;

## constructor
ok( $comment = new Config::Crontab::Comment( -data => '## testing 2' ) );
ok( $comment->data, '## testing 2' );
ok( $comment->dump, '## testing 2' );
undef $comment;

## constructor
ok( $comment = new Config::Crontab::Comment('## testing 3') );
ok( $comment->data, '## testing 3' );
ok( $comment->dump, '## testing 3' );
undef $comment;

## whitespace
ok( $comment = new Config::Crontab::Comment( -data => '	' ) );
ok( $comment->data, '	' );
ok( $comment->dump, '	' );
undef $comment;

## newline stripping
ok( $comment = new Config::Crontab::Comment( -data => "## no newline\n" ) );
ok( $comment->data, '## no newline' );
ok( $comment->dump, '## no newline' );
undef $comment;

## garbage in constructor should return undef
ok( ! defined($comment = new Config::Crontab::Comment('foo garbage')) );
undef $comment;
