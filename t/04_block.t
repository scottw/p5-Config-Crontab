use Test;
use blib;
BEGIN { plan tests => 126 };
use Config::Crontab;
ok(1);

my $block;
my $data;

## empty block
ok( $block = new Config::Crontab::Block );
ok( $block->dump, '' );
undef $block;

## single line constructor argument
ok( $block = new Config::Crontab::Block( -data => '## one line block' ) );
ok( $block->dump, <<_BLOCK_ );
## one line block
_BLOCK_
undef $block;

## a multi-line constructor argument
ok( $block = new Config::Crontab::Block( -data => <<_BLOCK_ ) );
## a comment
MAILTO=joe
5  0  *  *  *       rm -ri /
_BLOCK_
ok( $block->dump, <<_BLOCK_ );
## a comment
MAILTO=joe
5 0 * * * rm -ri /
_BLOCK_
undef $block;

## using methods
ok( $block = new Config::Crontab::Block );
ok( $block->data('## a comment') );
ok( $block->dump, "## a comment\n" );
undef $block;

## test newline
ok( $block = new Config::Crontab::Block );
ok( $block->data( "## single comment\n" ), "## single comment\n" );
ok( $block->dump, "## single comment\n" );  ## should have no extra newlines
undef $block;

## test multiline block via method
ok( $block = new Config::Crontab::Block );
$data = <<_DATAFOO_;
## this is foo
MAILTO=bob
#6 * 0 0 Sat /bin/saturday
_DATAFOO_
ok( $block->data($data), $data );
undef $block;

## set via lines constructor
my $comment1 = new Config::Crontab::Comment( -data => '## just a comment' );
my $env1     = new Config::Crontab::Env( -data => 'MAILTO=joe' );
my $event1   = new Config::Crontab::Event( -data => '5 0 * * * /bin/foo' );
my @lines = ( $comment1,
	      $env1,
	      $event1, );

ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
ok( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;

## set via lines method
ok( $block = new Config::Crontab::Block );
ok( $block->lines(\@lines) );
ok( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;


## set via -lines attribute; override with -data
ok( $block = new Config::Crontab::Block( -lines => \@lines,
					 -data  => $data ) );
ok( $block->data, $data );
ok( $block->dump, $data );
undef $block;


## try ->lines(undef) and see what happens
ok( $block = new Config::Crontab::Block( -lines => undef ) );
ok( $block->dump, '' );
undef $block;


## try adding some lines
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
my $event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
ok( $block->last($event2) );
ok( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 2 * * * /bin/bar
_LINES_

## try removing some lines
ok( $block->remove($event1) );
ok( defined $event1 );  ## should still be defined
ok( $event1->command, '/bin/foo' );
ok( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 2 * * * /bin/bar
_LINES_

## add it back in, remove some more
ok( $block->last($event1) );
ok( $block->remove($event2, $env1, $event1) );
ok( $block->dump, <<_LINES_ );
## just a comment
_LINES_

## remove the last object from the block and dump
ok( $block->remove($comment1), 0 );  ## remove method in scalar context
ok( $block->dump, '' );
undef $block;


## test replace
@lines = ( $comment1, $env1, $event1 );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
ok( $block->replace($event1 => $event2) );
ok( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 2 * * * /bin/bar
_LINES_
undef $block;


## try adding some in different positions
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
ok( $block->lines( [$event2, @lines] ) );
ok( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;


## make sure first, last only take objects
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
ok( $block->first($event2) );
ok( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_

## re-order a bunch of objects internally via first
ok( $block->first($event1, 'bogus stuff', $env1, $comment1) );
ok( $block->dump, <<_LINES_ );
5 0 * * * /bin/foo
MAILTO=joe
## just a comment
5 2 * * * /bin/bar
_LINES_

## same thing via last
ok( $block->last('diem', $comment1, $env1, $event1, 'carpe') );
ok( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;

## test select
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
my @select = $block->select( -type => 'comment' );
ok( scalar @select, 1 );

ok( $block->first( new Config::Crontab::Comment( -data => '## why?' ) ) );

@select = $block->select( -type => 'comment' );
ok( scalar @select, 2 );

my($obj) = $block->select( -type => 'comment');
ok( $obj->dump, '## why?' );
($obj) = $block->select( -type => 'event');
ok( $obj->dump, '5 0 * * * /bin/foo' );
($obj) = $block->select;
ok( $obj->dump, '## why?' );
undef $block;


## select some datetime attributes
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
ok( $block->last( new Config::Crontab::Event( -data => '10 10 * * Mon /bin/monday' ) ) );
ok( $block->select( -datetime_re => '0 \* \*'), 2 );
ok( $block->select( -datetime_re => ' 0 \* \*'), 1 );
ok( $block->select( -datetime => '5 0 * * *'), 1 );
undef $block;

## some select tests w/o the '-type' attribute
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
ok( $block->first( new Config::Crontab::Comment( -data => '## foo' ) ) );
ok( $block->select( -data_re => 'foo' ), 2 );
ok( $block->select( -data => 'foo' ), 0 );  ## no matching exact strings
undef $block;


## some empty criteria tests
ok( $block = new Config::Crontab::Block );
ok( $block->last( new Config::Crontab::Comment( -data => '## next is empty' ) ) );
ok( $block->last( new Config::Crontab::Comment ) );
ok( $block->last( new Config::Crontab::Comment( -data => '## next is empty' ) ) );
ok( $block->last( new Config::Crontab::Comment ) );
ok( $block->last( new Config::Crontab::Comment( -data => '## next is empty' ) ) );
ok( $block->last( new Config::Crontab::Comment ) );
ok( $block->last( new Config::Crontab::Comment( -data => '## next is not empty' ) ) );
ok( $block->last( new Config::Crontab::Env( -data => 'FOO=next' ) ) );
ok( $block->select( -bogus => '' ), 8 );
ok( $block->select( -data_re => 'next' ), 5 );
ok( $block->select( -data => '' ), 3 );
undef $block;


## create a crontab block
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
ok( $block->last( new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' ) ) );
ok( $block->last( new Config::Crontab::Event( -data => '10 4 * * 3 /bin/wednesday' ) ) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
10 4 * * 3 /bin/wednesday
_DUMPED_

## delete the backup event
for my $event ( $block->select( -type => 'event') ) {
    next unless $event->command =~ /\bbackup\b/;  ## look for backup command
    $block->remove($event); last;
}

ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
10 4 * * 3 /bin/wednesday
_DUMPED_

## compare string match vs regex
ok( $block->select( -type => 'event', -command => 'foo' ), 0 );
ok( $block->select( -type => 'event', -command_re => 'foo' ), 1 );
undef $block;


## set up block for up, down, first, last tests
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
$event2 = new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## add new event to bottom
ok( $block->down($event2) );  ## add at bottom
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## add new event to top
ok( $block->remove($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## add new event to top
ok( $block->first($event2) );
ok( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try last
ok( $block->last($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## move back to top
ok( $block->first($event2) );
ok( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try up (duplicate bug)
ok( $block->up($event2) );
ok( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try down
ok( $block->down($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## last, then down again
ok( $block->last($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## (duplicate bug)
ok( $block->down($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## try up
ok( $block->up($event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 1 * * * /sbin/backup
5 0 * * * /bin/foo
_DUMPED_
undef $block;


## setup tests for before, after
@lines = ( $comment1, $env1, $event1, );
ok( $block = new Config::Crontab::Block( -lines => \@lines ) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

$event2 = new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' );

ok( $block->before($comment1, $event2) );
ok( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

ok( $block->after($comment1, $event2) );
ok( $block->dump, <<_DUMPED_ );
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## see about non-existent references
my $event3 = new Config::Crontab::Event( -minute => 33, -command => '/sbin/uptime' );
ok( $block->before(undef, $event3) );
ok( $block->dump, <<_DUMPED_ );
33 * * * * /sbin/uptime
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## test active
ok( $block->active(0), 0 );
ok( $block->dump, <<_DUMPED_ );
#33 * * * * /sbin/uptime
## just a comment
#5 1 * * * /sbin/backup
#MAILTO=joe
#5 0 * * * /bin/foo
_DUMPED_

ok( $block->active(1) );
ok( $event3->active(0), 0 );
ok( $block->dump, <<_DUMPED_ );
#33 * * * * /sbin/uptime
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

ok( ! $block->active(undef) );
ok( $event3->active(1) );
ok( $block->dump, <<_DUMPED_ );
33 * * * * /sbin/uptime
## just a comment
#5 1 * * * /sbin/backup
#MAILTO=joe
#5 0 * * * /bin/foo
_DUMPED_

## a system block
undef $block;
$block = new Config::Crontab::Block;
$block->system(1);
$block->data(<<_DATA_);
## this is foo
#6 * 0 0 Sat rogerdodger /bin/saturday
_DATA_
ok( ($block->select(-type => 'event'))[0]->user, 'rogerdodger' );

undef $block;
$block = new Config::Crontab::Block( -system => 1,
				     -data   => <<_DATA_);
## this is foo
#6 * 0 0 Sat wonka /bin/saturday
_DATA_
ok( ($block->select(-type => 'event'))[0]->user, 'wonka' );

##
## remove many items using 'flag'
##
undef $block;
$block = new Config::Crontab::Block;
$block->system(1);
$block->data( <<'_DATA_');
1  5 * * *   bin    echo 1
2  5 * * *   bin    echo 2
3  5 * * *   bin    echo 3
4  5 * * *   bin    echo 4
5  5 * * *   bin    echo 5
6  5 * * *   bin    echo 6
7  5 * * *   bin    echo 7
8  5 * * *   bin    echo 8
9  5 * * *   bin    echo 9
10 5 * * *   bin    echo 10
11 5 * * *   bin    echo 11
12 5 * * *   bin    echo 12
13 5 * * *   bin    echo 13
14 5 * * *   bin    echo 14
15 5 * * *   bin    echo 15
16 5 * * *   bin    echo 16
17 5 * * *   bin    echo 17
_DATA_

## flag evens
my $count = 0;
for my $event ( $block->select( -type => 'event' ) ) {
    $event->flag('delete')
      if $count % 2 == 0;
    $count++;
}

## delete them
$block->remove( $block->select( -flag => 'delete' ) );

ok( $block->dump, <<_BLOCK_ );
2	5	*	*	*	bin	echo 2
4	5	*	*	*	bin	echo 4
6	5	*	*	*	bin	echo 6
8	5	*	*	*	bin	echo 8
10	5	*	*	*	bin	echo 10
12	5	*	*	*	bin	echo 12
14	5	*	*	*	bin	echo 14
16	5	*	*	*	bin	echo 16
_BLOCK_
