#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(-any);
use Data::Dumper;
use Config::General;
use Hash::Flatten;
use FindBin;
use lib "$FindBin::RealBin";
use WebAdminConfig;

my $cgi = CGI->new();
my $br = $cgi->br;

my $ls_register = "no";
my %par;
my @params = $cgi->param;

my $config;

#use parsing as in oppd.pl to get the same result.
$config = Config::General->new(
   -ConfigHash => \%par,
   -ApacheCompatible => 1,
   -AutoTrue => 1,
   -CComments => 0,
);
#%config = $config->getall;


print $cgi->header;
print $cgi->start_html(
  -title => 'Finish',
  -dtd   => '-//W3C//DTD HTML 4.01 Transitional//EN',
  -style => {'src'=>'../include/default.css'},
);


my @ls_urls;
my @ls_urls_orig = $cgi->param("ls_url");

foreach my $v (@ls_urls_orig){
  if (!$v eq ""){
    push @ls_urls, $v;
  }
}
$cgi->delete('ls_url');
$cgi->param(-name=>"ls_url", -value=>[@ls_urls]);

my $caller = $cgi->param("invoke");


foreach my $p (@params){
  if($p eq "ls_url[]") {
    next;
  }
  if ($p =~ /^syslog\_/) {
    my $new_parameter_name = $p;
    $new_parameter_name =~ s/syslog\_/syslog\-/g;
    my $value = $cgi->param("$p");
    $cgi->delete("$p");
    $cgi->param(-name=>"$new_parameter_name", -value=>"$value");
  }
  if (!$cgi->param("$p") or ($cgi->param("$p") eq "")){
    $cgi->delete("$p");
  }

  if ($p eq "Wizard" ||
      $p eq "invoke" ||
      $p eq "ServiceAdmin"){
    $cgi->delete("$p");
  }

  if ($p =~ /^hidden/){
    my $o = $p;
    $o =~ s/^hidden\.//;
    if (defined $cgi->param("$o")){
      $cgi->delete("$p");
    } else {
      my $v = $cgi->param("$p") || "";
      $cgi->param(-name=>"$o", -value=>"$v");
      $cgi->delete("$p");
    }
  }


  if ($cgi->param("$p") and ($cgi->param("$p") =~ /\s+/)){
    my $value = "\"" . $cgi->param("$p") . "\"";
    $cgi->param(-name=>"$p", -value=>"$value");
  }
}

my $par = Hash::Flatten::unflatten($cgi);
my @keys = keys %{$par};
foreach my $key (@keys){
  if ($key eq '' || $key eq "escape"){
    delete $par->{$key};
  }
}

my @ls_urls_config;
foreach my $value (@{$par->{'ls_url[]'}}) {
  push(@ls_urls_config, $value) unless (!$value or $value eq "");
}
$par->{ls_url} = \@ls_urls_config;
delete($par->{'ls_url[]'});

if (!(-e "$WebAdminConfig::configfile")){
  `touch $WebAdminConfig::configfile`;
}
$config->save_file("$WebAdminConfig::configfile", $par);
# apache user on RHEL
my $apache_userid = getpwnam("apache");
if(!$apache_userid) {
  # apache user on DEBIAN
  $apache_userid = getpwnam("www-data");
}
my $perfsonar_groupid = getgrnam("perfsonar");
if(!$apache_userid or !$perfsonar_groupid) {
  die("user ids for chown apache:perfsonar oppd.conf not found!");
}
my $chown_rv = chown($apache_userid, $perfsonar_groupid, "$WebAdminConfig::configfile");
unless($chown_rv == 0 or $chown_rv == 1) {
  die("chown apache:perfsonar oppd.conf failed: $!");
}

print $cgi->start_div({-class=>'main'});
print $cgi->start_div({-class=>'info'}, {-align=>'left'});
if ($caller and $caller eq 'Wizard'){

  print <<ENDHTML;
  <div  class="main">
  <div align="left" class="info">

  <br><h4 class="info_wizard">perfSONAR configuration Wizard</h4></br>
  <p class="info_wizard" >You have succesfully configured the service! You can restart oppd for the changes to take effect.</p>
   </div>
   </div>
ENDHTML

} else {
  
  print <<ENDHTML;
  <div class="info" >
  <p class="welcometextlavender">Service Administration<p>
  <p class="blueheader" >

  The oppd.conf file has been modified. Please restart oppd for any changes to take effect!
  </p>
  </div>
ENDHTML

}
print $cgi->end_div;
print $cgi->end_div;
print $cgi->end_html;
