use Test;
use blib;
BEGIN { plan tests => 75 };
use Config::Crontab;
ok(1);

my $ct;
my $crontabf = "_tmp_crontab.$$";
my @lines;
my $line;
my $block;

my $crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

## basic constructor tests (test auto-parse)
ok( $ct = new Config::Crontab( -file => $crontabf ) );
ok( $ct->file, $crontabf );
ok( $ct->dump, $crontabd );

## select tests
ok( @lines = $ct->select );
ok( scalar @lines, 15 );
ok( @lines = $ct->select( type => 'event' ) );
ok( scalar @lines, 7 );

## block tests
ok( $block = $ct->block($lines[0]) );  ## get the block this line is in
ok( $block->dump, <<_DUMPED_ );
## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

ok( $block = $ct->block($lines[1]) );
ok( $block->dump, <<_DUMPED_ );
## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

ok( $block = $ct->block($lines[2]) );
ok( $block->dump, <<'_DUMPED_' );
## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub
_DUMPED_

ok( $block = $ct->block($lines[3]) );
ok( $block->dump, <<'_DUMPED_' );
## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub
_DUMPED_


## regular expression match
ok( @lines = $ct->select( type   => 'event',
			  dow_re => '5' ) );
ok( scalar @lines, 4 );

## negative regular expression match
ok( @lines = $ct->select( type    => 'event',
			  dow_nre => '5' ) );
ok( scalar @lines, 3 );

## string exact match
ok( @lines = $ct->select( type => 'event',
			  dow  => '5' ) );
ok( scalar @lines, 2 );

## tight regular expression
ok( @lines = $ct->select( type   => 'event',
			  dow_re => '^5$' ) );
ok( scalar @lines, 2 );

## tight negative regular expression
ok( @lines = $ct->select( type    => 'event',
			  dow_nre => '^5$' ) );
ok( scalar @lines, 5 );

## multiple fields
ok( @lines = $ct->select( type   => 'event',
			  minute => '20',
			  dow_re => '^5$' ) );
ok( scalar @lines, 1 );

## more complex expressions
ok( @lines = $ct->select( type   => 'event',
			  dow_re => '(?:1|5)' ) );
ok( scalar @lines, 5 );

ok( @lines = $ct->select( type       => 'event',
			  command_re => 'dateish' ) );
ok( scalar @lines, 2 );

## try doing some selects where the field does not exist in the object
ok( @lines = $ct->select( -type   => 'event',
			  -foo_re => 'bar' ), 0 );
ok( scalar @lines, 0 );

## test remove blocks
$block = $ct->block($ct->select(type => 'comment', data_re => 'logs nightly'));
ok( $ct->remove($block) );

my $crontabd2 = <<'_CRONTAB_';
MAILTO=scott

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_
ok( $ct->dump, $crontabd2 );

## "move" tests

ok( $ct->last($block) );
ok( $ct->dump, <<'_DUMPED_' );
MAILTO=scott

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

## grab the line above where this block used to live
ok( ($line) = $ct->select(type => 'env', value => 'scott') );
ok( $line->dump, 'MAILTO=scott' );

## now insert this block after the block containing our line
ok( $ct->after($ct->block($line), $block) );
ok( $ct->dump, $crontabd );

## move it down one
ok( $ct->down($block) );

ok( $ct->dump, <<'_DUMPED_' );
MAILTO=scott

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_DUMPED_
undef $ct;


## test replace
ok( $ct = new Config::Crontab( -file => $crontabf ) );
$block = new Config::Crontab::Block( -data => <<_BLOCK_ );
## new replacement block
FOO=bar
6 12 * * Thu /bin/thursday
_BLOCK_
ok( $ct->replace($ct->block($ct->select(-data_re => 'run a backup')), $block) );
ok( $ct->dump, <<'_DUMPED_' );
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## new replacement block
FOO=bar
6 12 * * Thu /bin/thursday

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_DUMPED_


## test selection and poking an element
ok( $ct = new Config::Crontab( -file => $crontabf ) );
ok( ($ct->select(-command_re => 'weblog'))[0]->hour(5) );
ok( $ct->dump, <<'_DUMPED_' );
MAILTO=scott

## logs nightly
#30 5 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_DUMPED_
undef $ct;


## test block removal using block select
ok( $ct = new Config::Crontab );
ok( $ct->read( -file => $crontabf ) );
ok( $ct->dump, $crontabd );
for my $blk ( $ct->blocks ) {
    $blk->remove($blk->select( -type => 'comment' ));
    $blk->remove($blk->select( -type   => 'event',
			       -active => 0, ));
}
ok( $ct->dump, <<'_CRONTAB_' );
MAILTO=scott

20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

#MAILTO=phil

@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_
undef $ct;


## test block removal using crontab select
$ct = new Config::Crontab;
$ct->read( -file => $crontabf );
ok( $ct->dump, $crontabd );
$ct->remove($ct->select( -type => 'comment' ));
$ct->remove($ct->select( -type => 'event',
			 -active => 0 ));
ok( $ct->dump, <<'_CRONTAB_' );
MAILTO=scott

20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

#MAILTO=phil

@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_
undef $ct;


## test adding raw blocks
ok( $ct = new Config::Crontab );
ok( $ct->last(new Config::Crontab::Block( -data => <<_BLOCK_ )) );
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice
_BLOCK_
ok( $ct->dump, <<_BLOCK_ );
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice
_BLOCK_

ok( $ct->last(new Config::Crontab::Block( -data => <<_BLOCK_ )) );
## eat pizza
35 * * * 1-5 /bin/eat --pizza
_BLOCK_

ok( $ct->dump, <<_BLOCK_ );
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice

## eat pizza
35 * * * 1-5 /bin/eat --pizza
_BLOCK_

unlink $crontabf;
$crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * ipartner $HOME/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 ipartner $HOME/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 root /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 root /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 scott env DISPLAY=tub:0 $HOME/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 phil $HOME/fetch_version -q

## start spamd
@reboot root /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

$ct = new Config::Crontab( -file => $crontabf, -system => 1 );
ok( ($ct->select(-command_re => 'weblog'))[0]->user, 'ipartner' );
ok( ($ct->select(-command_re => 'fetch_image'))[0]->user, 'scott' );
ok( ($ct->select(-user => 'phil'))[0]->dow, '1-5' );
ok( ($ct->select(-user => 'root'))[1]->minute, '40' );
ok( ($ct->select(-user => 'root'))[2]->special, '@reboot' );

## test pretty print for system crontab files
unlink $crontabf;
$crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30	4	*	*	*	ipartner	$HOME/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35	4	*	*	1	ipartner	$HOME/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20	2	*	*	5	root	/usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40	2	*	*	5	root	/usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13	9	*	*	1-5	scott	env DISPLAY=tub:0 $HOME/bin/fetch_image

## check versions
#MAILTO=phil
#10	5	*	*	1-5	phil	$HOME/fetch_version -q

## start spamd
@reboot					root	/usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

## test the purdy printin' for system crontab files
$ct = new Config::Crontab( -file => $crontabf, -system => 1 );
ok( $ct->dump, $crontabd );

## test select_blocks
my @blocks = $ct->select_blocks( -index => 1 );
ok( ($blocks[0]->select( -type => 'comment' ))[0]->data, '## logs nightly' );

@blocks = $ct->select_blocks( -index => 2 );
ok( ($blocks[0]->select( -type => 'event' ))[0]->user, 'ipartner' );

@blocks = $ct->select_blocks( -index => [0, 4, 7] );
ok( ($blocks[0]->select( -type => 'env' ))[0]->value, 'scott' );
ok( ($blocks[1]->select( -type => 'comment' ))[0]->data, '## fetch ufo' );
ok( $blocks[2], undef );

##
## try some owner tests
##
undef $ct;
$ct = new Config::Crontab;
$ct->owner('root');
ok( $ct->owner, 'root' );

## stricter
$ct->strict(1);
eval { $ct->owner('somereallybogususername8838293') };
ok( $@ =~ qr(Unknown user)i );

eval { $ct->owner("root\0 2>/dev/null; cat /etc/passwd") };
ok( $@ =~ qr(Illegal username)i );

END {
    unlink $crontabf;
}
