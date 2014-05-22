package perfSONAR::Client::LS;
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

#TODO
# - Please make me a proper class! There should be an object for every service
#   and this class brings everything together.
# - Replace the usage of $log with something more useful.

use strict;
use warnings;

#DEBUG
use Data::Dumper;
#/DEBUG

use Socket;
use Socket6;


BEGIN {
  use vars qw($VERSION @ISA @EXPORT);
  use Exporter;
  @ISA = qw(Exporter);

  # set the version for version checking
  $VERSION     = 0.10;
  # if using RCS/CVS, this may be preferred
  #$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
  #@EXPORT      = qw(heartbeat deregister);          # Symbols to autoexport (:DEFAULT tag)
}

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

# Setup everything und sent initial registration ("first" heartbeat).
sub init {
	my %p = @_;
  	%services = %{$p{services}}; @ls_url = @{$p{ls_url}};
  	$hostname = $p{hostname}; $port = $p{port};
  	$organization = $p{organization}; $contact = $p{contact};
  	$log = $p{log};
	$protocol = "http"; #Default
	
	# Stroe hostport or LSToolreg will override
	my $hostport = $port;
	
	# Look first if hostname is set if not exit
	if (!defined($hostname) || length($hostname) <= 1){
		$log->error("Hostname parameter in configuration file is not set. Please set it");
		die;
	}
	
  	#first registration:
  	foreach my $service (keys %services){
		if ($service =~ /LSToolreg/){
  			my %modparam = %{$services{$service}->{'handler'}->{MODPARAM}};
    		foreach my $tool (keys %modparam){
    			#register tool only if availible
    			if ($services{$service}->{'handler'}->{MODPARAM}->{$tool}->{REGTOOL} eq "yes"){
    				$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceName}  = $modparam{$tool}{'ServiceName'};
    				$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceType}  = $modparam{$tool}{'ServiceType'};    
    				$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceDescription}  = $modparam{$tool}{'ServiceDescription'};
    				$services{$service}{handler}->{MODPARAM}->{ls_param}->{Organization}  = $modparam{$tool}{'Organization'};
    				$protocol = $modparam{$tool}{'protocol'};
    				$port = $modparam{$tool}{'port'};
    				create_register_message($service);
    				send_all_registration($messages{$service}{"register_msg"}, $service, $tool);
    			}
    		}
    		
		}else{
			$port = $hostport;     
    		create_register_message($service);
    		send_all_registration($messages{$service}{"register_msg"}, $service);
		}
  	}
}


# Send keepalive messages for each service
sub heartbeat {
	
	if ($reg_services){
  		foreach my $service (keys %{$reg_services}){ #get services from global hash
    		my $message;
    		foreach my $url (keys %{$reg_services->{$service}}){
    			if (exists $reg_services->{$service}->{$url}->{KEEPALIVEMSG}){
        			$message = $reg_services->{$service}->{$url}->{KEEPALIVEMSG}->clone();

					$log->info("Sending keepalive for $service to $url");
        			my $response = perfSONAR::sendReceive(
          				message => $message,
          				uri => $url,
        			);
        			if ($response){
          				write_message($response, "keepalive-response");
          				#TODO What to do if keepalive fails? At the moment: Nothing. 
          				my $eventtype = ($response->{dom}->getElementsByTagNameNS("$nmwg", "eventType"))[0]->textContent;
          				my $datumstring = ($response->{dom}->getElementsByTagNameNS("$nmwgr", "datum"))[0]->textContent;
          				$log->info("Keepalive for $service returend $eventtype: $datumstring");
          				
          				#sometimes LS is rebooted and
          				# LS key is lost of we get 
          				# error for keepalive so try
          				#registration again 
          				if ($eventtype =~ /error.ls/){
          					$log->warn("Error in keepalive trying to reregister service to: $url");
          					my $re_reg_msg = $reg_services->{$service}->{$url}->{LSREGMSG};
          					send_registration($re_reg_msg,$service,$url);
          				}
        			} else { #no response... 
          				$log->errot("Sending keepalive for $service: No response from Lookup Server!");
        			}
    			}#End if exist    			
    		}#eND FORECH $url
		}#End foreach $service
	}#End if$reg_services
} 


sub create_register_message{
  my $service = shift;

  # read in template for LS registration message and fill in module specific
  # values:
  my $message = NMWG::Message->new();
  $message->parse_xml_from_file($register_template);
  my $servicenode = ($message->{dom}->getElementsByTagNameNS("$psservice", "service"))[0];
  
  $message->add_element_NS($servicenode, "serviceName", "$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceName}", $psservice);
  $message->add_element_NS($servicenode, "organization", "$services{$service}{handler}->{MODPARAM}->{ls_param}->{Organization}", $psservice);
  if ($service =~ /LSToolreg/){
  	$message->add_element_NS($servicenode, "accessPoint", "$protocol://$hostname:$port", $psservice);
  }else{
  	$message->add_element_NS($servicenode, "accessPoint", "http://$hostname:$port/services/$service", $psservice);
  }
  $message->add_element_NS($servicenode, "serviceType", "$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceType}", $psservice);
  $message->add_element_NS($servicenode, "description", "$services{$service}{handler}->{MODPARAM}->{ls_param}->{ServiceDescription}", $psservice);
  
  $log->debug($message->as_string());
  
  my $datanode = ($message->{dom}->getElementsByTagNameNS("$nmwg", "data"))[0];
  my $metanode = $message->add_attribute (namespace => $nmwg,
                                          parent => $datanode,
                                          nodename => "metadata",
                                          id => "topo-metadata",
                                         );
  my $subjectnode = $message->add_attribute (namespace => $nmwg,
                                            parent => $metanode,
                                            nodename => "subject",
                                            id => "topo-subject",
                                           );
  my @addresses = lookup_interfaces();

  my $nodenode = $message->add_attribute (namespace => $nmtb,
                                          prefix => "nmtb",
                                          parent => $subjectnode,
                                          nodename => "node",
                                         );
  
  foreach my $addr (@addresses) {
    my $name = lookup_hostname($addr);
    next unless $name;
    $message->add_attribute (namespace => $nmtb,
                             prefix => "nmtb",
                             parent => $nodenode,
                             nodename => "name",
                             type => "dns",
                             value => $name,
                            );
  }
  foreach my $addr (@addresses) {
    my $addr_type;

    if ($addr =~ /:/) {
      $addr_type = "ipv6";
    } else {
      $addr_type = "ipv4";
    }

    my $portnode = $message->add_attribute (namespace => $nmtl3,
                                            prefix => "nmtl3",
                                            parent => $nodenode,
                                            nodename => "port",
                                           );
    $message->add_attribute (namespace => $nmtl3,
                             prefix => "nmtb",
                             parent => $portnode,
                             nodename => "address",
                             type => $addr_type,
                             value => $addr,
                            );
  }
  
  #We need eventypes only
  # at the moment nothing more to do
  my $ds_nmwg = perfSONAR::DataStruct::NMWG->new();
  #$log->info(Dumper($services{$service}));
  my $et = $ds_nmwg->getEventtypeforservice($services{$service}->{handler}{MAINSERVICE});
  $message->add_element_NS($metanode, "eventType", "$et", $nmwg);
  
  my $paramnode = $message->add_attribute (namespace => $nmwg,
                                           parent => $metanode,
                                           nodename => "parameters",
                                           );
  if (exists $services{$service}->{"keyword"}){
    my $keywordnode = $message->add_attribute (namespace => $nmwg,
                                               parent => $paramnode,
                                               nodename =>"parameter",
                                               name => "keyword",
                                               value => $services{$service}->{keyword},
                                              );
  }

  if ($service =~/MA/){
    $services{$service}->{handler}->get_meta_info($message);
  }
  $messages{$service}{"register_msg"} = $message;
}

sub check_response {
  my $response = shift;
  my $service = shift;
  
  my ($errorstring, $metaid) = $response->parse_all;
  if($errorstring){
    $log->error($errorstring);
  }
  #parse content, write to log if successfull registration or error happened
  my $eventtype;
  my $key;
  foreach my $meta (keys %{$response->{"metadataIDs"}}){
  	next if ($meta eq "serviceLookupInfo");
     $eventtype = $response->{"metadataIDs"}{$meta}{"eventType"};
    
    if (!$eventtype =~ /success/){
      $log->info("LS returned $eventtype for service $service");
      #return;
    } else {
      if ($eventtype =~ /register/){
        $key = $response->{"metadataIDs"}{$meta}{"key"}{"lsKey"};
        $log->info("successfully registered service $service with key $key");
        $messages{$service}{"ls_key"} = $key;
      }
    }
  }
  return $key;
}

sub create_keepalive_message {
  my $key = shift;

  my $message = NMWG::Message->new();
  $message->parse_xml_from_file($keepalive_template);
  my $paramnode = ($message->{dom}->getElementsByTagNameNS("$nmwg", "parameters"))[0];
  $message->add_attribute(parent => $paramnode, nodename => "parameter", value => $key, name => "lsKey");
  write_message($message, "keepalive");
  return $message;
}

sub send_registration{
	
	my $message = shift;
	my $service = shift;
	my $url = shift;
	
	my $response = perfSONAR::sendReceive(
          message => $message->clone,
          uri => $url,
    );
    if ($response){
      write_message($response, "register-response");
      my $key = check_response($response, $service);
      if ($key){
      	$reg_services->{$service}->{$url}->{LSKEY} = $key;
      	$reg_services->{$service}->{$url}->{KEEPALIVEMSG} = create_keepalive_message($key);
      	$reg_services->{$service}->{$url}->{LSREGMSG} = $message->clone;
      } else {
        my $eventtype = ($response->{dom}->getElementsByTagNameNS("$nmwg", "eventType"))[0]->textContent;
        my $datumstring = ($response->{dom}->getElementsByTagNameNS("$nmwgr", "datum"))[0]->textContent;
        $log->error("error registering service $service with $eventtype: $datumstring");
      }
    } else {
    	#TODO should we delete this url
      	$log->error("error registering service $service: No response from Lookup Server!");
    }
}  

sub send_all_registration {

  my $message = shift;
  my $service = shift;
  my $tool = "";
  
  if (@_){
  	$tool = shift;
  }

  write_message($message, "register");
  foreach my $url (@ls_url){
  	if ($tool){
  		$log->info("registering service $service -> $tool to $url");
  	}else{
  		$log->info("registering service $service to $url");
  	}
  	#send message
  	send_registration($message,$service,$url);
  }
}



sub deregister{
	
  #send deregistration
  if ($reg_services){
  	#read in deregistration template:
	my $message = NMWG::Message->new();
	$message->parse_xml_from_file($deregister_template);
	
  	foreach my $service (keys %{$reg_services}){
    	my $deregmsg = $message->clone;
    	my $parametersnode = (
      		$deregmsg->{dom}->getElementsByTagNameNS("$nmwg", "parameters")
    	)[0];
    	my $key_parameter = $deregmsg->add_attribute(
            parent => $parametersnode,
            nodename => "parameter",
            name => "lsKey"
    	);
    	foreach my $url (keys %{$reg_services->{$service}}){
    		my $key = $reg_services->{$service}->{$url}->{LSKEY};
    		$key_parameter->appendText($key);
    		write_message($deregmsg, "deregister");
			$log->info("deregistering service $service from $url");
			my $response = perfSONAR::sendReceive(
            	message => $deregmsg->clone,
           	 	uri => $url,
			);
      		if ($response){
        		write_message($response, "dereg-response");
        		$log->info("successfully deregistered service $service with key $key");
        		#TODO do something interesting with result
        		#$response->parse_meta;
        		#$response->parse_data;
      		} else {
        		$log->info("could not deregister $key: No response from Looukup Server!");
      		}
    	}#End forech my $url
    }
  }
  #lay down to die
}

sub get_key{
#TODO not implemented yet
}

sub re_register{
#TODO not implemented yet
}

sub lookup_interfaces {
    my @ret_interfaces = ();

    open(IFCONFIG, "/sbin/ifconfig |");
    my $is_eth = 0;
    while(<IFCONFIG>) {
        if (/Link encap:([^ ]+)/) {
            if (lc($1) eq "ethernet") {
                $is_eth = 1;
            } else {
                $is_eth = 0;
            }
        }
        next if (not $is_eth);

        if (/inet \w+:(\d+\.\d+\.\d+\.\d+)/) {
            push @ret_interfaces, $1;
        } elsif (/inet6 \w+: (\d*:[^\/ ]*)(\/\d+)? .*:Global/) {
            push @ret_interfaces, $1;
        }
    }
    close (IFCONFIG);
    return @ret_interfaces;
}

sub lookup_hostname {
    my $ip = shift;

    my $result;
    if ($ip =~ /:/) {
      # IPv6
      $result = gethostbyaddr(inet_pton(AF_INET6, $ip), AF_INET6);
    } else {
      # IPv4
      $result = gethostbyaddr(inet_aton($ip), AF_INET);
    }
    return $result;
}

sub write_message{
  my $message = shift;
  my $name = shift;

  if ($debug_write){
    my $timestamp = time;
    open (FH, ">", "$name-$timestamp.xml");
    print FH $message->as_string();
    close FH;
    sleep(1);
  }
}


1;

