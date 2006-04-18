use Test;
use blib;
BEGIN { plan tests => 2 };
use Config::Crontab;
ok(1);

my $crontabf = ".tmp_crontab.$$";
my $crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

my $ct = new Config::Crontab( -file => $crontabf );
$ct->remove_tab;

ok( ! -e $crontabf );

END {
    unlink $crontabf;
}
