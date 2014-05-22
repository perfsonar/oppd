package WebAdminConfig;

require Exporter;

use strict;
use warnings;

our @EXPORT = qw(configfile configpath);

use Config::General;
use Getopt::Long 2.32 qw(:config auto_help auto_version prefix=--);

use Data::Dumper;
use Hash::Flatten qw(flatten unflatten);

#my $configpath = "/etc";
our $configpath = "/usr/lib/perfsonar/services/oppd/etc";
our $configfile = "$configpath/oppd.conf";

sub get_config {

  my %Config = ();
  my $Config;
  $Config = Config::General->new(
    -ConfigFile => $configfile,
    -ApacheCompatible => 1,
    -AutoTrue => 1,
    -CComments => 0,
  );
  %Config = $Config->getall;

  #fill in defaults

  $Config{detach} = 1 unless exists $Config{detach};
  $Config{logfile} = "/var/log/oppd.log" unless exists $Config{logfile};
  $Config{pidfile} = "/var/run/oppd.pid" unless exists $Config{pidfile};
  $Config{syslog} = 0 unless exists $Config{syslog};
  $Config{"syslog-host"} = "" unless exists $Config{"syslog-host"};
  $Config{"syslog-ident"} = "oppd" unless exists $Config{"syslog-ident"};
  $Config{"syslog-facility"} = "daemon" unless exists $Config{"syslog-facility"};
  $Config{loglevel} = "notice" unless exists $Config{loglevel};
  $Config{ls_url} = "" unless exists $Config{ls_url};
  $Config{ls_register} = 0 unless exists $Config{ls_register};
  $Config{keepalive} = 3600 unless exists $Config{keepalive};
  $Config{max_proc} = 5 unless exists $Config{max_proc};
  $Config{hostname} = "" unless exists $Config{hostname};
  $Config{port} = 8090 unless exists $Config{port};
  $Config{organization} = "" unless exists $Config{organization};
  $Config{contact} = "" unless exists $Config{contact};
  $Config{auth} = 0 unless exists $Config{auth};
  $Config{as_url} = "" unless exists $Config{as_url};
  $Config{ssl} = 0 unless exists $Config{ssl};
  $Config{"service.MP/BWCTL.store_url"} = "" unless exists $Config{"service.MP/BWCTL.store_url"};
  $Config{"service.MP/BWCTL.store"} = 0 unless exists $Config{"service.MP/BWCTL.store"};
  $Config{"service.MP/BWCTL.keyword"} = "" unless exists $Config{"service.MP/BWCTL.keyword"};
  $Config{"service.MP/BWCTL.description"} = "" unless exists $Config{"service.MP/BWCTL.description"};
  $Config{"service.MP/BWCTL.tool"} = "" unless exists $Config{"service.MP/BWCTL.tool"};



  my $flat = flatten(\%Config);

  my %flat_names;
  foreach my $key (keys %{$flat}){
    $key =~ /([\:\w]+)$/;
    $flat_names{$1} = $key;
  }
  return ($flat, %flat_names);
}

1;
