#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(-any);
use Data::Dumper;

my $cgi = CGI->new();
my $br = $cgi->br;

my %par;
my @params = $cgi->param;

my $oppd_bin = "/usr/lib/perfsonar/services/oppd/bin/oppd.pl";
my $error = "";

print $cgi->header;
print $cgi->start_html(
  -title => 'Test deplyment',
  -dtd   => '-//W3C//DTD HTML 4.01 Transitional//EN',
  -style => {'src'=>'../include/main.css'},
);

print $cgi->body({-style => 'background-color: #FFFFFF'});
print $cgi->start_div({-class=>'centerWindow'});
print $cgi->p({-class=>'welcometext'}, "Welcome to the perfSONAR service web administration interface");
print $cgi->p({-class=>'heading1'}, "Deployment test");

if (defined $cgi->param("testit")){
  if (!test_depl()){
    print $cgi->start_table({-align=>'center', -class=> 'testdeplsucc'});
    print $cgi->tr($cgi->td());
    print $cgi->tr($cgi->td($br, "Starting/Stopping of oppd was successful."));
    print $cgi->end_table;

  }else{
    print $cgi->start_table({-align=>'center', -class=> 'testdeplfail'});
    print $cgi->tr($cgi->td());
    print $cgi->tr($cgi->td($br, $br, 'Deployment test failed! The following error occured while trying to start oppd:', $br, $br, $error));
    print $cgi->end_table;
  }
}else{

  print $cgi->start_table({-align=>'left', -class=> 'testdeplmain'});
  print $cgi->tr($cgi->td());
  print $cgi->tr($cgi->td('Click on the  <b>start test</b>  button to check if you have deployed oppd and the BWCTL MP service correctly.'));
  print $cgi->tr($cgi->td());
  print $cgi->tr($cgi->td($cgi->center($cgi->br, $cgi->a({href=>'?testit=true',-target=>'_self',-class=>'testdeplstartbn'}))));

  print $cgi->end_table;

  print $cgi->end_div;
}
print $cgi->end_html;

sub test_depl {

  my $pidfile = '/tmp/oppd.pid';

  #my @oppd_command = ("/usr/bin/perl", "/usr/lib/perfsonar/services/oppd/bin/oppd.pl", "--config=/usr/lib/perfsonar/services/oppd/etc/oppd.conf", "--detach", "--nologfile", "--pidfile=/tmp/oppd.pid", "--port=3030");
  #system(@oppd_command);
  #if ($? != 0) {
  #  $error = "failed to execute: $!";
  #  warn "failed to execute: $!";
  #  return -1;
  #}
  #else {
  #  #printf "child exited with value %d\n", $? >> 8;
  #  warn("child exited with value ".($? >> 8));
  #  #return -1;
  #}

  my $oppd_output = `/usr/bin/perl /usr/lib/perfsonar/services/oppd/bin/oppd.pl --config=/usr/lib/perfsonar/services/oppd/etc/oppd.conf --detach --nologfile --pidfile=/tmp/oppd.pid --port=3030 2>&1`;

  $error = $oppd_output;

  if (-e $pidfile && -s $pidfile){
    my $oppid;
    open(PIDFILE, "$pidfile") or die("opening pid file /tmp/oppd.pid failed: $!");
    while (<PIDFILE>){
      chomp ($oppid = $_);
      warn("got PID $oppid out of /tmp/oppd.pid");
    }
    if(kill("TERM", $oppid) < 1) {
      warn("killing test oppd with $oppid failed: $!");
      $error .= "\nkilling test oppd with $oppid failed: $!\n";
      return 1;
    }
    if(unlink($pidfile) != 1) {
      warn("unlinking pidfile for test oppd failed: $!");
      $error .= "\nunlinking pidfile for test oppd failed: $!\n";
      return 1;
    }
    return 0;
  }
  else {
    return 1;
  }
}
