#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(-any);
use Data::Dumper;
use Config::General;
use FindBin;
use lib "$FindBin::RealBin";
use WebAdminConfig;

my $cgi = CGI->new();
my $br = $cgi->br;

my %params;

my @par = $cgi->param;

my %Config = ();
my $Config;

if (!(-e "$WebAdminConfig::configfile")){
  `touch $WebAdminConfig::configfile`;
}
$Config = Config::General->new(
  -ConfigFile => $WebAdminConfig::configfile,
  -ApacheCompatible => 1,
  -AutoTrue => 1,
  -CComments => 0,
);
%Config = $Config->getall;


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


<script type="text/javascript">
function checkIt(el) {
  if (el.value ==document.getElementById("Vl_"+el.name).value) {
    document.getElementById(el.name).style.display = "block";
  }
  else {
    document.getElementById(el.name).style.display = "none";
    }
  }    
</script>

<div  class="main">
<div class="top"><br>Please fill in all fields. Mandatory fields are marked with an asterisk.</br></div>
<div  class="properties">
<form action="finish.pl" method="post">
ENDHTML

my %mp_bwctl;

if(!$Config{service}{"MP/BWCTL"}){
  print <<ENDHTML;
<input type=hidden name="hidden.service.MP/BWCTL.module" value="MP::BWCTL">
ENDHTML
} else {

  %mp_bwctl = %{$Config{service}{"MP/BWCTL"}};

  foreach my $k (keys %mp_bwctl){
    if (ref($mp_bwctl{$k}) eq "HASH"){
      foreach my $l (keys %{$mp_bwctl{$k}}){
        print <<ENDHTML;
<input type=hidden name="hidden.service.MP/BWCTL.$k.$l" value="$mp_bwctl{$k}{$l}">
ENDHTML
      }
    } else {
      print <<ENDHTML;
<input type=hidden name="hidden.service.MP/BWCTL.$k" value="$mp_bwctl{$k}">
ENDHTML
    }
  }
}

print <<ENDHTML;


<p class="groupheading">BWCTL Configuration:</p>

<div  id="" style="display:block;">
<table align="center">
<tr><td>Enter the path to the BWCTL binary:</td><td>
<input class="input_style" onmouseover="setTip(null,'$mp_bwctl{module_param}{command}','#D5E9D4')" type="text"  name="service.MP/BWCTL.module_param.command" size=40 value="$mp_bwctl{module_param}{command}"/>
</td></tr>
</table>
</div>

<p class="groupheading">LS Configuration:</p>
<table align="center">
<input type="hidden" value="yes" id="Vl_ls_register" />
<tr><td>Do you wish to register with an LS?</td><td>
ENDHTML

my $ls_register_on = undef;
if(defined($Config{ls_register}) and $Config{ls_register} =~ /(on|true|1|yes)/) {
  $ls_register_on = 1;
}
my $as_enabled_on = undef;
if(defined($Config{auth}) and $Config{auth} =~ /(on|true|1|yes)/) {
  $as_enabled_on = 1;
}

print '<input type="radio" name="ls_register" value="yes"  onclick="checkIt(this);"'.($ls_register_on ? ' checked="checked"' : '');
print '>yes</input>';
print '<input type="radio" name="ls_register" value="no"  onclick="checkIt(this);"'.($ls_register_on ? '' : ' checked="checked"');
print '>no</input>';

print <<ENDHTML;
</td></tr>
</td></tr>
</table>
ENDHTML
print '<div id="ls_register" style="display:'.($ls_register_on ? 'block' : 'none').';">';
print <<ENDHTML;
<table align="center" id="ls_table">
<tr><td>Enter the service name:<span class="greenasterisk" >*</span></td><td>
<input class="input_style" onmouseover="setTip(null,'$mp_bwctl{name}','#D5E9D4')"  type="text"  name="service.MP/BWCTL.name" size=40 value="$mp_bwctl{name}"/>
</td></tr>

<tr><td>Give a description of the  service:</td><td>
<input class="input_style" onmouseover="setTip(null,'$mp_bwctl{description}','#D5E9D4')" type="text"  name="service.MP/BWCTL.description" size=40 value="$mp_bwctl{description}"/>
</td></tr>

<tr><td>Enter the contact email address:</td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{contact}','#D5E9D4')" type="text"  name="contact" size=40 value="$Config{contact}"/>
</td></tr>

<tr><td>Enter the name of the organization running this service:</td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{organization}','#D5E9D4')" type="text"  name="organization" size=40 value="$Config{organization}"/>
</td></tr>

<tr><td valign="top">Give the LS url:<span class="greenasterisk" >*</span></td>
<td id="td1">

ENDHTML

if (ref $Config{ls_url} eq "ARRAY"){ #more than one LS url in config file

  foreach my $url (@{$Config{ls_url}}){
    print <<ENDHTML;
    <input class="input_style" onmouseover="setTip(null,'$url','#D5E9D4')" type="text"  name="ls_url[]" size=40 value="$url"/><br/>
ENDHTML
  }
}else {
  print <<ENDHTML;
  <input class="input_style" onmouseover="setTip(null,'$Config{ls_url}','#D5E9D4')" type="text"  name="ls_url[]" size=40 value="$Config{ls_url}"/><br/>
ENDHTML
}

print <<ENDHTML;
<input id="ls_button" align="left" type="button" class="add_ls_button" value="add another LS url" onclick="add('blub')"/>
</td></tr>

<tr><td>Give the registration interval in seconds:</td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{keepalive}','#D5E9D4')" type="text"  name="keepalive" size=40 value="$Config{keepalive}"/>
</td></tr>

<tr><td>Give the service hostname:<span class="greenasterisk" >*</span></td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{hostname}','#D5E9D4')" type="text"  name="hostname" size=40 value="$Config{hostname}"/>
</td></tr>

<tr><td>Give the service port:<span class="greenasterisk" >*</span></td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{port}','#D5E9D4')" type="text"  name="port" size=40 value="$Config{port}"/>
</td></tr>

</table>

</div>

<p class="groupheading">AS Configuration:</p>
<table align="center">
<input type="hidden" value="yes" id="Vl_auth" />
<tr><td>Do you wish to enable authentication?</td><td>
ENDHTML
print '<input type="radio" name="auth" value="yes"  onclick="checkIt(this);"'.($as_enabled_on ? ' checked="checked"' : '');
print '>yes</input>';
print '<input type="radio" name="auth" value="no"  onclick="checkIt(this);"'.($as_enabled_on ? '' : ' checked="checked"');
print '>no</input>';

print <<ENDHTML;
</td></tr>
</td></tr>
</table>
ENDHTML
print '<div id="auth" style="display:'.($as_enabled_on ? 'block' : 'none').';">';
print <<ENDHTML;
<table align="center">
<tr><td>Enter the URL address of the Authentication Service:<span class="greenasterisk" >*</span></td><td>
<input class="input_style" onmouseover="setTip(null,'$Config{as_url}','#D5E9D4')"  type="text"  name="as_url" size=40 value="$Config{as_url}"/>
</td></tr>
</table>

<input type="hidden" name="invoke" value="Wizard"/>

</div>
<input align="right" input id="Button" class="submit_button" type="submit" name="Wizard" value="Submit Changes" />
</form>
</div>
</div>
</body>
</html>
ENDHTML
