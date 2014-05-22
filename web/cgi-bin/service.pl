#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(-any);
use CGI::Carp; #DEBUG
use Data::Dumper;
use Config::General;

use FindBin;
use lib "$FindBin::RealBin";
use WebAdminConfig;

my $cgi = CGI->new();
my $br = $cgi->br;

my %params;

my @par = $cgi->param;

my ($flat, %flat_names) = WebAdminConfig::get_config();

print $cgi->header;
print $cgi->start_html(
  -title => 'perfSONAR services configuration wizard',
  -dtd   => '-//W3C//DTD HTML 4.01 Transitional//EN',
  -style => {'src'=>'../include/default.css'},
);


print <<ENDHTML;
<script src="../include/Service_Admin.js"></script>
<script src="../include/wz_tooltip.js"></script>
<script src="../include/Add.js"></script>
<div class="tablessContent" >
</div>
<div class="manage">
<p class="welcometextlavender">Service Settings Table</p>
<br>The listed settings are optional. You can configure them to customise your installation. Place your mouse cursor on a setting to display help.</br><br/>
<form action="finish.pl" method="post">
ENDHTML
foreach my $key (keys %{$flat}){

print <<ENDHTML;
<input type=hidden name="hidden.$key" value="$flat->{$key}">
ENDHTML
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
<th class="blueheader">General</th>

<td onmouseover="setTip(this,' Determines whether the perfSONAR process is detached from the controlling terminal and run in the background (1) or not (0).','#C7C7F2')">
detach
</td>
<td>
ENDHTML
if ($flat->{$flat_names{detach}} =~ /(on|true|1|yes)/){
  print <<ENDHTML;
<input type="radio" checked name="$flat_names{detach}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" name="$flat_names{detach}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
} else {
  print <<ENDHTML;
<input type="radio" name="$flat_names{detach}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" checked name="$flat_names{detach}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
}
print <<ENDHTML;
</td>
</tr>
<tr class="lightgrey">
<td/>

<td onmouseover="setTip(this,'The path to the pid file, including the pid file\'s name.','#C7C7F2')">
pidfile
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{pidfile}" value="$flat->{$flat_names{pidfile}}"  onmouseover="setTip(null,'$flat->{$flat_names{pidfile}}','#C7C7F2')"  />
</td>
</tr>
<tr class="lightgrey">
<td/>

<td onmouseover="setTip(this,'The maximum number of processes to be spawned for a request.','#C7C7F2')">
max_proc
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{max_proc}" value="$flat->{$flat_names{max_proc}}"  onmouseover="setTip(null,'$flat->{$flat_names{max_proc}}','#C7C7F2')"  />
</td>
</tr>

<tr class="darkgrey" >
<th class="blueheader">LS</th>
<td onmouseover="setTip(this,'Determines whether Lookup Service registration is enabled (1) or not (0).','#C7C7F2')" >
ls_register
</td>
<td>
ENDHTML


if ($flat->{$flat_names{ls_register}} =~ /(on|true|1|yes)/){
  print <<ENDHTML;
<input type="radio" checked name="$flat_names{ls_register}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" name="$flat_names{ls_register}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
} else {
  print <<ENDHTML;
<input type="radio" name="$flat_names{ls_register}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" checked name="$flat_names{ls_register}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
}
print <<ENDHTML;
</td>
</tr>
<tr class="darkgrey">
<td/>

<td onmouseover="setTip(this,'The interval (seconds) in which a KeepAlive request is sent to ensure that the service\'s registration with the Lookup Service is kept alive.','#C7C7F2')">
keepalive
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{keepalive}" value="$flat->{$flat_names{keepalive}}"  onmouseover="setTip(null,'$flat->{$flat_names{keepalive}}','#C7C7F2')"  />
</td>
</tr>
<tr class="darkgrey">
<td/>

<td valign="top" onmouseover="setTip(this,'The URL address of the LS service.','#C7C7F2')">
ls_url
</td>
<td id="td1">
ENDHTML

if (defined $flat_names{"ls_url:0"}){
  foreach my $key (%{$flat}){
    my $url;
    if ($key =~/^ls_url/){
      $url = $flat->{$flat_names{$key}}; 
      
      print <<ENDHTML;
      <input class="input_style_blue" size=60 name="ls_url[]" onmouseover="setTip(null,'$url','#D5E9D4')" type="text"  value="$url"/><br/>
ENDHTML
    }
  }
}else{
  print <<ENDHTML;
  <input class="input_style_blue" size=60 name="ls_url[]" onmouseover="setTip(null,'$flat->{$flat_names{ls_url}}','#D5E9D4')" type="text"   value="$flat->{$flat_names{ls_url}}"/><br/>
ENDHTML
}

print <<ENDHTML;

<input id="ls_button" align="left" type="button" class="add_ls_button_blue" value="add another LS url"  onclick="add('blue')"/>
</td>
</tr>
<tr class="darkgrey">
<td/>

<td onmouseover="setTip(this,'The URL address of the service configured by this configuration file.','#C7C7F2')">
hostname
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{hostname}" value="$flat->{$flat_names{hostname}}"  onmouseover="setTip(null,'$flat->{$flat_names{hostname}}','#C7C7F2')"  />
</td>
</tr>
<tr class="darkgrey">
<td/>

<td onmouseover="setTip(this,'The port by which requests are sent to the service configured by this configuration file.','#C7C7F2')">
port
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{port}" value="$flat->{$flat_names{port}}"  onmouseover="setTip(null,'$flat->{$flat_names{port}}','#C7C7F2')"  />
</td>
</tr>
<tr class="darkgrey">
<td/>

<td onmouseover="setTip(this,'The name of the organization who who is deploying the service.','#C7C7F2')">
organization
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{organization}" value="$flat->{$flat_names{organization}}"  onmouseover="setTip(null,'$flat->{$flat_names{organization}}','#C7C7F2')"  />
</td>
</tr>
<tr class="darkgrey">
<td/>

<td onmouseover="setTip(this,'The email address of the person who manages the service.','#C7C7F2')">
contact
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{contact}" value="$flat->{$flat_names{contact}}"  onmouseover="setTip(null,'$flat->{$flat_names{contact}}','#C7C7F2')"  />
</td>
</tr>

<tr class="lightgrey" >
<th class="blueheader">Authentication</th>
<td onmouseover="setTip(this,'Determines whether authentication is enabled (1) or not (0)','#C7C7F2')" >
auth
</td>
<td>
ENDHTML

if ($flat->{$flat_names{auth}} =~ /(on|true|1|yes)/){
  print <<ENDHTML;
<input type="radio" checked name="$flat_names{auth}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" name="$flat_names{auth}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
} else {
  print <<ENDHTML;
<input type="radio" name="$flat_names{auth}" value="1" onclick="checkIt(this);">on</input>
<input type="radio" checked name="$flat_names{auth}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
}
print <<ENDHTML;
</td>
</tr>
<tr class="lightgrey">
<td/>
<td onmouseover="setTip(this,'The URL address of the Authentication Service.','#C7C7F2')">
as_url
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{as_url}" value="$flat->{$flat_names{as_url}}"  onmouseover="setTip(null,'$flat->{$flat_names{as_url}}','#C7C7F2')"  />

</td>
</tr>
<tr class="darkgrey" >
<th class="blueheader">BWCTL Module</th>
<td onmouseover="setTip(this,'The service name.','#C7C7F2')">
name
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{name}" value="$flat->{$flat_names{name}}"  onmouseover="setTip(null,'$flat->{$flat_names{name}}','#C7C7F2')"  />

</td>
</tr>
<tr class="darkgrey">
<td/>
<td onmouseover="setTip(this,'The description of the service.','#C7C7F2')">
description
</td>
<td>
  <input type="text" class="input_style_blue" size=60 name="$flat_names{description}" value="$flat->{$flat_names{description}}"  onmouseover="setTip(null,'$flat->{$flat_names{description}}','#C7C7F2')"  />


</td>
</tr>
<tr class="darkgrey">
<td/>
<td onmouseover="setTip(this,'The service tool.','#C7C7F2')">
tool
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{tool}" value="$flat->{$flat_names{tool}}"  onmouseover="setTip(null,'$flat->{$flat_names{tool}}','#C7C7F2')"  />

</td>
</tr>
<tr class="darkgrey">
<td/>
<td onmouseover="setTip(this,'The path to the BWCTL binary. Omitting path, searches \$PATH.','#C7C7F2')">
command
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{command}" value="$flat->{$flat_names{command}}"  onmouseover="setTip(null,'$flat->{$flat_names{command}}','#C7C7F2')"  />

</td>
</tr>

<tr class="darkgrey" >
<td/>
<td onmouseover="setTip(this,'Determines whether store action to SQL MA is enabled (1) or not (0)','#C7C7F2')" >
store
</td>
<td>
ENDHTML

if ($flat->{$flat_names{store}} =~ /(on|true|1|yes)/){
  print <<ENDHTML;
    <input type="radio" checked name="$flat_names{store}" value="1" onclick="checkIt(this);">on</input>
    <input type="radio" name="$flat_names{store}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
} else {
  print <<ENDHTML;
    <input type="radio" name="$flat_names{store}" value="1" onclick="checkIt(this);">on</input>
    <input type="radio" checked name="$flat_names{store}" value="0" onclick="checkIt(this);">off</input>
ENDHTML
}
print <<ENDHTML;
</td>
</tr>

<tr class="darkgrey">
<td/>
<td onmouseover="setTip(this,'The URL address to the SQL MA the data is stored into.','#C7C7F2')">
store_url
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{store_url}" value="$flat->{$flat_names{store_url}}"  onmouseover="setTip(null,'$flat->{$flat_names{store_url}}','#C7C7F2')"  />

</td>
</tr>


<tr class="darkgrey">
<td/>
<td onmouseover="setTip(this,'Keyword for identifying organizational groups or projects.','#C7C7F2')">
keyword
</td>
<td>
<input type="text" class="input_style_blue" size=60 name="$flat_names{keyword}" value="$flat->{$flat_names{keyword}}"  onmouseover="setTip(null,'$flat->{$flat_names{keyword}}','#C7C7F2')"  />

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
