#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(-any);
use Data::Dumper;

my $cgi = CGI->new();
my $br = $cgi->br;

my %par;
my @params = $cgi->param;

my $error = "";

print $cgi->header;
print $cgi->start_html(
  -title => 'Restart service',
  -dtd   => '-//W3C//DTD HTML 4.01 Transitional//EN',
  -style => {'src'=>'../include/main.css'},
);

print $cgi->body({-style => 'background-color: #FFFFFF'});
print $cgi->start_div({-class=>'centerWindow'});
print $cgi->p({-class=>'welcometext'}, "Welcome to the perfSONAR service web administration interface");
print $cgi->p({-class=>'heading1'}, "Restart service");

my $result = restart();

print $cgi->p("Restarting service returned: $result");

print $cgi->end_html;


sub restart{

  my @result = `./restart_script.pl`;
  return join (' ', @result);
}
