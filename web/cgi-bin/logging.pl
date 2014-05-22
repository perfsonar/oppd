#!/usr/bin/perl

use strict;
use warnings;

use Config::General;

use CGI qw(-any);
use Data::Dumper;

use FindBin;
use lib "$FindBin::RealBin";
use WebAdminConfig;


my $cgi = CGI->new();
my $br = $cgi->br;

my %params;

my @par = $cgi->param;

my ($flat, %flat_names) = WebAdminConfig::get_config;

print $cgi->header;
print $cgi->start_html(
  -title => 'perfSONAR services configuration wizard',
  -dtd   => '-//W3C//DTD HTML 4.01 Transitional//EN',
  -style => {'src'=>'../include/default.css'},
);

print <<ENDHTML;
<script src="../include/Service_Admin.js">
</script>

<script src="../include/wz_tooltip.js">
</script>

<div class="tablessContent" >
</div>
<div class="manage">
<p class="welcometextlavender">Logging Settings Table</p>
<br>The listed settings are optional. You can configure them to customise your installation. Place your mouse cursor on a setting to display help.</br><br/>
<form action="finish.pl" method="post">
ENDHTML


foreach my $key (keys %{$flat}){
  if($key =~ /^ls_url/) {
    print "<input type=hidden name=\"ls_url[]\" value=\"$flat->{$key}\">";
  }
  else {
  print <<ENDHTML;
  <input type=hidden name="hidden.$key" value="$flat->{$key}">
ENDHTML
  }
}

print <<ENDHTML;
<table>
<tr class="headerlavender">
<th>Group</th>
<th>Service Setting Name</th>
<th>Service Setting Value</th>
</tr>
<tr/>
<tr class="lightgrey" >
<th class="blueheader">Logging</th>

<td onmouseover="setTip(this,'Determines whether log messages are written to the syslog or not. Set it to no, off, 0, or false to disable sending messages to system log. Set it to yes, on, 1, or true to enable sending messages to system log. You can use this option together with "logfile". Messages will then be written to both, log file and system log.','#C7C7F2')">
syslog
</td>
<td>
ENDHTML

if ($flat->{$flat_names{syslog}} =~ /(on|true|1|yes)/){
  print <<ENDHTML;
  <input type="radio" checked name="$flat_names{syslog}" value="1" onclick="checkIt(this);">on</input>
  <input type="radio" name="$flat_names{syslog}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
} else {
  print <<ENDHTML;
  <input type="radio" name="$flat_names{syslog}" value="1" onclick="checkIt(this);">on</input>
  <input type="radio" checked name="$flat_names{syslog}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
}

print <<ENDHTML;

</td>
</tr>
<tr class="lightgrey">
<td/>
<td onmouseover="setTip(this,'The path to the log file, including the log file\'s name. Set it to no, off, 0, or false to disable log file usage. Set it to yes, on, 1, or true to enable logging to default log file \"/var/log/oppd.log\".','#C7C7F2')">
logfile
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{logfile}" value="$flat->{$flat_names{logfile}}"  onmouseover="setTip(null,'$flat->{$flat_names{logfile}}','#C7C7F2')"  />
</td>
</tr>
<tr class="lightgrey">
<td/>

<td onmouseover="setTip(this,'Send syslog to external syslog host. If this option is set to a dns name or ip address, all system log messages are forwarded to the specified remote host. If set to no, off, 0, false, or "" logging is done locally.','#C7C7F2')">
syslog host
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="syslog_host" value="$flat->{'syslog-host'}"  onmouseover="setTip(null,'$flat->{"syslog-host"}','#C7C7F2')"  />
</td>
</tr>
<tr class="lightgrey">
<td/>


<td onmouseover="setTip(this,'Identification string for system log messages. This string will be prepended to all messages in the system log. Default: oppd','#C7C7F2')">
syslog ident
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="syslog_ident" value="$flat->{'syslog-ident'}"  onmouseover="setTip(null,'$flat->{"syslog-ident"}','#C7C7F2')"  />
</td>
</tr>
<tr class="lightgrey">
<td/>

<td onmouseover="setTip(this,'Type of program for system logging. This string will be used as the system log facility for messages sent to the system log. See your syslog documentation for the facilities available on your system.','#C7C7F2')">
syslog facility
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="syslog_facility" value="$flat->{'syslog-facility'}"  onmouseover="setTip(null,'$flat->{"syslog-facility"}','#C7C7F2')"  />
</td>
</tr>
<tr class="lightgrey">
<td/>



<td onmouseover="setTip(this,'The log level used for logging to syslog and to the log files. This option is used for setting the verbosity of the running daemon.','#C7C7F2')">
loglevel
</td>
<td>
<select name="loglevel" size="1" class="select_blue">
ENDHTML


if ("debug (0)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="debug">debug (0)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="debug">debug (0)</option>
ENDHTML
}

if ("info (1)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="info">info (1)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="info">info (1)</option>
ENDHTML
}

if ("notice (2)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="notice">notice (2)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="notice">notice (2)</option>
ENDHTML
}

if ("warning (3)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="warning">warning (3)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="warning">warning (3)</option>
ENDHTML
}

if ("error (4)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="error">error (4)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="error">error (4)</option>
ENDHTML
}

if ("critical (5)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="critical">critical (5)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="critical">critical (5)</option>
ENDHTML
}

if ("alert (6)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="alert">alert (6)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="alert">alert (6)</option>
ENDHTML
}

if ("emergency (7)" =~ /$flat->{$flat_names{loglevel}}/){
  print <<ENDHTML;
  <option selected value="emergency">emergency (7)</option>
ENDHTML
} else {
  print <<ENDHTML;
  <option value="emergency">emergency (7)</option>
ENDHTML
}

print <<ENDHTML;
</select>  

</td>
</tr>

<tr/>
<tr>
<th/><td/><td>
<input class="floatResetButton" id="ResetButton" type="reset" class="submit_button" value="Cancel" /><input class="floatSubmitButton" type="submit" id="Button" name="ServiceAdmin" value="Submit Changes" class="submit_button" /></td>


</tr>
</table>
</form>
</div>
</body>
</html>
ENDHTML
