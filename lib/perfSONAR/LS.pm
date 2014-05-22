package perfSONAR::LS;
#  
#  Copyright 2010 Verein zur Foerderung eines Deutschen Forschungsnetzes e. V.
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#       http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  
#  
=head1 NAME

perfSONAR::LS - Main class for Lookup Service (LS) registration 

=head1 DESCRIPTION

This is the main class for registering a service to a Lookup Service (LS). 
It includes all functions which are needes to register a service to LS. It is only used if the parameter

$ds->{LS_REGISTER}

is set to True. Then the start function is used. Some parameters are get from the main configuration
file oppd.conf. For example LS url or hostname. The service specific parameters are get  from the service 
configuration file. For this the ls_param block is used. For details open this files fro example:

oppd.d/owamp.conf


 
=cut

use strict;
use warnings;
 
 use Log::Log4perl qw(get_logger);
 use NMWG::Message;
#use perfSONAR qw(print_log);

my $register_template;
my $deregister_template;
my $keepalive_template; 


if (-e "$FindBin::RealBin/../etc/"){
  $register_template = "$FindBin::RealBin/../etc/LS_register.xml";
  $deregister_template = "$FindBin::RealBin/../etc/LS_deregister.xml";
  $keepalive_template = "$FindBin::RealBin/../etc/LS_keepalive.xml";
} else {
  $register_template = "/etc/oppd.d/LS_register.xml";
  $deregister_template = "/etc/oppd.d/LS_deregister.xml";
  $keepalive_template = "/etc/oppd.d/LS_keepalive.xml";
}

my $psservice = "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/";
my $nmwg = "http://ggf.org/ns/nmwg/base/2.0/";
my $nmtb = "http://ogf.org/schema/network/topology/base/20070828/";
my $nmtl3 = "http://ogf.org/schema/network/topology/l3/20070828/";
my $nmwgr = "http://ggf.org/ns/nmwg/result/2.0/";

our %services = ();
our (
  $hostname, $port, $organization, $contact, $log,$protocol
);

our @ls_url = ();
my %messages;
my $reg_services ={};
my $debug_write = 0;

 
=head1 Methods:

=head2 parseConfiguration($ds)

This function should only be called at the geginning of a service. It use the ls_param block of the service
and sotes the key and value which should be registered in a a hash variable:

$self->{LS_PARAM}

This is used to create the registration request.

=cut

sub parseConfiguration{
	my ($self) = @_;
	my $module_param_ref = $self->{MODPARAM};
	
	print "$module_param_ref->{ls_param}->{Name}\n";
	
}
 
 1;
 

