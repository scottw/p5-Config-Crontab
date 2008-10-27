use Test;
use blib;
BEGIN { plan tests => 128 };
use Config::Crontab;
ok(1);

my $event;

## empty object
ok( $event = new Config::Crontab::Event );
ok( $event->dump, '' );
undef $event;

## setting via datetime
ok( $event = new Config::Crontab::Event( -datetime => '@hourly',
					 -command  => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '@hourly' );
ok( $event->command, '/usr/sbin/backup_everything' );
ok( $event->dump, '@hourly /usr/sbin/backup_everything' );
undef $event;

## setting via datetime
ok( $event = new Config::Crontab::Event( -datetime => '@hourly',
					 -command  => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '@hourly' );
ok( $event->datetime, '@hourly' );
ok( $event->command, '/usr/sbin/backup_everything' );
ok( $event->dump, '@hourly /usr/sbin/backup_everything' );
undef $event;

## setting via datetime
ok( $event = new Config::Crontab::Event( -datetime => '5 0 * * *',
					 -command  => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '5 0 * * *' );
ok( $event->special, '' );
ok( $event->minute, 5 );
ok( $event->hour, 0 );
undef $event;

## setting via datetime
ok( $event = new Config::Crontab::Event( -datetime => '*/5 0 * * *',
					 -command  => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '*/5 0 * * *' );
ok( $event->special, '' );
ok( $event->minute, '*/5' );
ok( $event->hour, 0 );
undef $event;

## setting via special
ok( $event = new Config::Crontab::Event( -special => '@monthly',
					 -command => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '@monthly' );
ok( $event->special, '@monthly' );
ok( $event->minute, '*' );
ok( $event->hour, '*' );
undef $event;

## FIXME: currently no checks for bogus 'special' strings
## FIXME: if we ever do checking on -special, these tests will have
## FIXME: to be changed
## setting via special
ok( $event = new Config::Crontab::Event( -special => '5 0 1 * *',
					 -command => '/usr/sbin/backup_everything' ) );
ok( $event->datetime, '5 0 1 * *' );
ok( $event->special, '5 0 1 * *' );
ok( $event->minute, '*' );
ok( $event->hour, '*' );
undef $event;

## setting via -data
ok( $event = new Config::Crontab::Event( -data => '@reboot /usr/sbin/food' ) );
ok( $event->special, '@reboot' );
ok( $event->datetime, '@reboot' );
ok( $event->command, '/usr/sbin/food' );
undef $event;

## setting via -data: -data overrides all other attributes
ok( $event = new Config::Crontab::Event( -data     => '@reboot /usr/sbin/food',
					 -active   => 0,  ## ignored
					 -hour     => 5,  ## ignored
					 -special  => '@daily',  ## ignored
					 -datetime => '5 2 * * Fri',  ## ignored
				       ) );
ok( $event->special, '@reboot' );
ok( $event->datetime, '@reboot' );
ok( $event->command, '/usr/sbin/food' );
ok( $event->hour, '*' );
ok( $event->dump, '@reboot /usr/sbin/food' );
undef $event;

## setting via -data
ok( $event = new Config::Crontab::Event( -data => '6 1 * * Fri /usr/sbin/backup' ) );
ok( $event->special, '' );
ok( $event->datetime, '6 1 * * Fri' );
ok( $event->command, '/usr/sbin/backup' );
undef $event;

## try some disabled events
ok( $event = new Config::Crontab::Event( -data => '## 7 2 * * Mon /bin/monday' ) );
ok( $event->active, 0 );
ok( $event->datetime, '7 2 * * Mon' );
ok( $event->command, '/bin/monday' );
undef $event;

## setting via attributes
ok( $event = new Config::Crontab::Event( -minute  => 0,
					 -hour    => 4,
					 -command => '/usr/sbin/foo' ) );
ok( $event->hour, 4 );
ok( $event->minute, 0 );
ok( $event->command, '/usr/sbin/foo' );
ok( $event->special, '' );
ok( $event->dump, '0 4 * * * /usr/sbin/foo' );
ok( $event->active(0), 0 );
ok( $event->dump, '#0 4 * * * /usr/sbin/foo' );
ok( $event->data, '0 4 * * * /usr/sbin/foo' );
undef $event;

## setting via attributes: datetime takes precedence over fields
ok( $event = new Config::Crontab::Event( -minute   => 5,
					 -datetime => '@reboot',
					 -command  => '/usr/sbin/doofus' ) );
ok( $event->minute, '*' );
ok( $event->hour, '*' );
ok( $event->special, '@reboot' );
ok( $event->datetime, '@reboot' );
ok( $event->command, '/usr/sbin/doofus' );
# do not undef $event here

## resetting object via methods
ok( $event->datetime('6 8 * Mar Fri,Sat,Sun'), '6 8 * Mar Fri,Sat,Sun' );
ok( $event->special, '' );
ok( $event->dump, '6 8 * Mar Fri,Sat,Sun /usr/sbin/doofus' );
# do not undef $event here

## resetting object via methods
ok( $event->datetime([6, 9, '*', 'Mar', 'Fri,Sun'], '6 9 * Mar Fri,Sun') );
ok( $event->special, '' );
ok( $event->dump, '6 9 * Mar Fri,Sun /usr/sbin/doofus' );
# do not undef here

## resetting object via methods
ok( $event->datetime([6, '*/2', '*', 'Mar', 'Fri,Sun'], '6 */2 * Mar Fri,Sun') );
ok( $event->special, '' );
ok( $event->dump, '6 */2 * Mar Fri,Sun /usr/sbin/doofus' );
# do not undef here

## resetting object via methods
ok( $event->datetime(['@daily'], '@daily') );
ok( $event->special, '@daily' );
ok( $event->dump, '@daily /usr/sbin/doofus' );
undef $event;

## set pieces via methods
ok( $event = new Config::Crontab::Event( -minute => 5 ) );
ok( $event->hour(0), 0 );
ok( $event->command('/usr/bin/foo'), '/usr/bin/foo' );
ok( $event->data, '5 0 * * * /usr/bin/foo' );
ok( $event->dump, '5 0 * * * /usr/bin/foo' );
ok( $event->active(0), 0 );
ok( $event->data, '5 0 * * * /usr/bin/foo' );
ok( $event->dump, '#5 0 * * * /usr/bin/foo' );
undef $event;

## try some more esoteric values
ok( $event = new Config::Crontab::Event );
ok( $event->minute('23,53'), '23,53' );
ok( $event->hour('*/2'), '*/2' );
ok( $event->month('1,3,Apr,Aug'), '1,3,Apr,Aug' );
ok( $event->dow('Fri,Sat,Sun'), 'Fri,Sat,Sun' );
ok( $event->command('/bin/foo'), '/bin/foo' );
ok( $event->dump, '23,53 */2 * 1,3,Apr,Aug Fri,Sat,Sun /bin/foo' );
ok( $event->minute('5-55/3'), '5-55/3' );
ok( $event->hour('0-4,8-12'), '0-4,8-12' );
ok( $event->dump, '5-55/3 0-4,8-12 * 1,3,Apr,Aug Fri,Sat,Sun /bin/foo' );
undef $event;

## failure via -data
ok( ! defined($event = new Config::Crontab::Event( -data => 'foo' )) );
undef $event;

## failure via -data
ok( ! defined($event = new Config::Crontab::Event( -data => 1 )) );
undef $event;

## test system (user) syntax via -data
ok( $event = new Config::Crontab::Event( -data => '3 2 1 * Fri joe foo bar',
					 -system => 1 ) );
ok( $event->minute, 3 );
ok( $event->dow, 'Fri' );
ok( $event->user, 'joe' );
ok( $event->command, 'foo bar' );
undef $event;

## test system (user) syntax via methods
$event = new Config::Crontab::Event;
ok( $event->system, 0 );
$event->hour('5');
$event->minute('26');
$event->user('joe');
ok( $event->system );
$event->command('/bin/bash');
ok( $event->dump, "26\t5\t*\t*\t*\tjoe\t/bin/bash" );
undef $event;

## test system (user) syntax via -data and methods
$event = new Config::Crontab::Event( -data => '3 2 1 * Fri foo bar' );
ok( $event->system, 0 );
$event->user('joe');
ok( $event->system, 1 );
ok( $event->dump, "3\t2\t1\t*\tFri\tjoe\tfoo bar" );
undef $event;

## test system (user) syntax via -data and methods
$event = new Config::Crontab::Event;
$event->system(1);
$event->data( "3\t2\t1\t*\tFri\tfoo\tbar" );
ok( $event->user, 'foo' );
ok( $event->command, 'bar' );
undef $event;

## test system (user) syntax (REMEMBER: -data always overrides all other params except 'system'!)
$event = new Config::Crontab::Event( -data   => '3 2 1 * Fri foo bar',
				     -user   => 'joe', );  ## ignored
ok( $event->system, 0 );
ok( $event->user, '' );
ok( $event->command, 'foo bar' );
ok( $event->dump, "3 2 1 * Fri foo bar" );
undef $event;

## test system (user) syntax
$event = new Config::Crontab::Event( -data   => '3 2 1 * Fri foo bar',
				     -system => 1 );
ok( $event->system, 1 );
ok( $event->user, 'foo' );
ok( $event->command, 'bar' );
ok( $event->dump, "3\t2\t1\t*\tFri\tfoo\tbar" );
undef $event;

## test system (user) syntax
$event = new Config::Crontab::Event;
$event->data('3 2 1 * Fri foo bar');
$event->user('joe');
ok( $event->system, 1 );
ok( $event->command, 'foo bar');
ok( $event->dump, "3\t2\t1\t*\tFri\tjoe\tfoo bar" );
$event->user('zelda');
ok( $event->data, "3\t2\t1\t*\tFri\tzelda\tfoo bar" );

$event->system(0);
$event->data('1 3 5 * Wed blech winnie');
ok( $event->dump, '1 3 5 * Wed blech winnie' );
ok( $event->user, '' );
undef $event;

## test nolog option (SuSE-specific syntax)
$event = new Config::Crontab::Event;
$event->data('5 10 * * * /bin/echo "quietly now"');
$event->nolog(1);
ok( $event->dump, '-5 10 * * * /bin/echo "quietly now"' );
$event->minute(50);
ok( $event->dump, '-50 10 * * * /bin/echo "quietly now"' );
$event->nolog(0);
ok( $event->dump, '50 10 * * * /bin/echo "quietly now"' );

## make it into a system event
$event->user('joe');
$event->nolog(1);
ok( $event->dump, qq!-50\t10\t*\t*\t*\tjoe\t/bin/echo "quietly now"! );
