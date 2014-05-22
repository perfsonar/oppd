package perfSONAR::DataStruct::NMWG;
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

perfSONAR::DataStruct::NMWG

=head1 DESCRIPTION

This is the NMWG DataStruct. Use this to convert NMWG messages to the oppd DataStruct format.To call this
create a object calling the new constructor. For details look at the description of the new method.
=head1 Methods

=cut

#TODOS
#$ds->{REQUESTMSG}->return_result_code check retrn lines

use strict;
use warnings;


#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 0.52;

#Here are everything to use
use Log::Log4perl qw(get_logger);
use Carp;

use perfSONAR::SOAP::Message;
use perfSONAR::Request;
use perfSONAR::SOAP::HTTP::Request;

=head2 new({})

The constructor.

=cut

sub new{
	my ($class) = @_;
	my $self = {};
	$self->{LOGGER} = get_logger(__PACKAGE__);
	
	$self->{NS}->{MPBWCTL} = "http://ggf.org/ns/nmwg/tools/iperf/2.0/";
	$self->{NS}->{MPOWAMP} = "http://ggf.org/ns/nmwg/tools/owamp/2.0/";
	$self->{NS}->{OWAMPSUMMARY} = "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921/";
	$self->{NS}->{STORE} = "http://ggf.org/ns/nmwg/ops/store/2.0/";
	$self->{NS}->{RAW} = "http://ggf.org/ns/nmwg/tools/owd/raw";
	$self->{NS}->{HADES} = "http://ggf.org/ns/nwmg/tools/hades/aggregated";
	$self->{NS}->{HOPLIST} = "http://ggf.org/ns/nmwg/tools/hades/traceroute/hoplist/2.0/";
	$self->{NS}->{RAW} = "http://ggf.org/ns/nmwg/tools/owd/raw";

	$self->{HADES}->{RESPARAMS}->{OCCUR} = undef;
	$self->{HADES}->{ACTIONS} = {
    
    ippm_aggregated => [
                        "http://ggf.org/ns/nmwg/tools/hades/",
                        "http://ggf.org/ns/nmwg/characteristic/delay/summary/",
                        "http://ggf.org/ns/nwmg/tools/hades/aggregated/",
                       ],
    ippm_raw => [
                        "http://ggf.org/ns/nmwg/tools/owd/raw/",
                        "http://ggf.org/ns/nmwg/characteristic/delay/one-way/",
                ],
    };
	
	
	
	push @{$self->{"supportedEventtypes"}},

    {
    bwctl => "http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
    iperf => "http://ggf.org/ns/nmwg/tools/iperf/2.0/",
    owamp => "http://ggf.org/ns/nmwg/tools/owamp/2.0/",
    hades => "http://ggf.org/ns/nmwg/tools/hades/",
    summary => "http://ggf.org/ns/nmwg/characteristic/delay/summary//",
    owd_raw => "http://ggf.org/ns/nmwg/tools/owd/raw/",
    hades_agg => "http://ggf.org/ns/nwmg/tools/hades/aggregated/",
    one_way_delay => "http://ggf.org/ns/nmwg/characteristic/delay/one-way/",
    select => "http://ggf.org/ns/nmwg/ops/select/2.0",
    hoplist => "http://ggf.org/ns/nmwg/tools/hades/traceroute/hoplist/2.0/",
    echo => "http://schemas.perfsonar.net/tools/admin/echo/2.0/",
    store => "http://ggf.org/ns/nmwg/ops/store/2.0/",
    selftest => "http://schemas.perfsonar.net/tools/admin/selftest/1.0/"
    };    
	
	bless $self, $class;
	return $self;
}

=head2 nmwg2ds({})

Converts a nmwg message to a data struct. As parameter is a NMWG::Message is needed. 

=cut
sub nmwg2ds{
    my ($self, $nmwg,$ds) = @_;
    my $messagetype = $nmwg->get_message_type();
    my $select;
    
    $ds->{DSTYPE} = 'NMWG';
    $ds->{REQUESTMSG} = $nmwg;
    
    ($ds->{SERVICE}->{NAME} = $ds->{URI}) =~ s/^.*\/services\///;
    $ds->{SERVICE}->{NAME} =~ s/\/$//;
    $self->{LOGGER}->info("Requested service: $ds->{SERVICE}->{NAME}");
    #$self->{LOGGER}->info("Message: $messagetype ");
    #$self->{LOGGER}->info($nmwg->as_string());
    #Check messagetype
    if (!$self->NMWGcheckMessagetype($messagetype,\$ds)){
    	$self->{LOGGER}->error("Error in checking message type");
        my $et = "error.nmwg.action_not_supported";
        $ds->{REQUESTMSG}->return_result_code($et, "$ds->{ERRMSG}", "message");
        $ds->{ERROROCCUR} = 1;
        return;
    }   
    
    
    #Now get the new messagetype
    $messagetype = $ds->{REQUESTMSG}->get_message_type();   
            
    my %module_ets = %{pop(@{$self->{"supportedEventtypes"}})};

    #create {"dataIDs"} and {"metadataIDs"}
    #hashes from document
    my ($errorstring, $metaid) = $ds->{REQUESTMSG}->parse_all;
    if($errorstring){
        $self->{LOGGER}->error($errorstring);
        $ds->{REQUESTMSG}->return_result_code("error.common.parse_error", "$errorstring", $metaid);
        $ds->{ERROROCCUR} = 1;
        return;
    }
    
    #check if at least one metadata and one data element is in message
    if(!($ds->{REQUESTMSG}->{"metadataIDs"})){
        $errorstring = "No metadata definition in message.";
        $self->{LOGGER}->error($errorstring);
        $ds->{REQUESTMSG}->return_result_code("error.common.message", "$errorstring", "message");
        $ds->{ERROROCCUR} = 1;
        return;
    }
    if(!(defined $ds->{REQUESTMSG}->{"dataIDs"})){
        $errorstring = "No data trigger in message.";
        $self->{LOGGER}->error($errorstring);
        $$ds->{RETURNMSG} = $ds->{REQUESTMSG}->return_result_code("error.common.message", "$errorstring", "message");
        $ds->{ERROROCCUR} = 1;
        return;
    }
    
    #do some checks on metadata content
    foreach my $meta (keys %{$ds->{REQUESTMSG}->{"metadataIDs"}}){
        #check for unknown eventTypes
        my $et = $ds->{REQUESTMSG}->{"metadataIDs"}{$meta}{"eventType"};
        #$self->{LOGGER}->info("Eventype: $et");
        #look for echo
        if ($et =~ /admin\/echo/  || $et eq "echo"){
            $ds->{DOECHO} = 1;;
            $self->{LOGGER}->info("Get Echo request");
        }
        #look for selftest
        if ($et =~ /admin\/selftest/ || $et eq "echo"){
            $ds->{DOSELFTEST} = 1;
            $self->{LOGGER}->info("Get selftest request");
        }
        
        my $found = undef;
        foreach my $key (keys %module_ets){
            next unless ($module_ets{$key} =~ /$et/);
            $found = 1;
        }
        
        if (!defined $found){
            my $errorstring = "Unknown eventType: $et";
            $self->{LOGGER}->error($errorstring);
            $ds->{REQUESTMSG}->return_result_code("error.common.event_type_not_supported", $errorstring, $meta);
            $ds->{ERROROCCUR} = 1;
            return;
        }
        
        #Eventtype is defined we can use it for result data
        $self->{EVENTTYPE} = $et;
        
        #check times
        my $startTime = $ds->{REQUESTMSG}->{"metadataIDs"}{$meta}{"startTime"};
        my $endTime = $ds->{REQUESTMSG}->{"metadataIDs"}{$meta}{"endTime"};
        if ($endTime && $startTime && ($endTime < $startTime)){
            my $errorstring = "Illegal time duration specified: " .
            "$endTime is later than $startTime!";
            $self->{LOGGER}->info($errorstring);
            $ds->{REQUESTMSG}->return_result_code("error.common.parse_error", $errorstring, $meta);
            $ds->{ERROROCCUR} = 1;
            return;
        }
    } #End forech
    
    
    #add metadata parameters to data hashes
    ($errorstring, $metaid) = $ds->{REQUESTMSG}->concatenate_params;
    if ($errorstring){
        $self->{LOGGER}->error($errorstring);
        $ds->{REQUESTMSG}->return_result_code("error.common.parse_error", "$errorstring", $metaid);
        $ds->{ERROROCCUR} = 1;
        return;
    }
        
    #Prepare for each dataID a measurement
    #Getparameters
    my $params = {};
    foreach my $dataid (keys %{$ds->{REQUESTMSG}->{"dataIDs"}}){
       my $datablock = $ds->{REQUESTMSG}->{"dataIDs"}{$dataid};
       my %parameters;
       #$self->{LOGGER}->info($datablock[0]);
       foreach my $key (keys %{$datablock}){ #get eventtypes
        next if ($key eq "node" || $key eq "metaref" ); #Get only evebttypes
            foreach my $k (keys %{$datablock->{$key}}){
            	#$self->{LOGGER}->debug(Dumper($k));
                if (!defined $parameters{$k}){
                    if ($k eq "src" || $k eq "dst"){
                        $parameters{$k} = $datablock->{$key}{$k}{"value"};
                    } else {
                        $parameters{$k} = $datablock->{$key}->{$k};
                   }
                }# End if (!defined $parameters
            }#End foreach my $k
            if ( $key =~ /store/){
            	#This parameters are store data
            	$params->{$parameters{'dataref'}}->{STORE}->{DOIT} = 1;
            	$self->{LOGGER}->info("Get store request for measurement data");
            }
            if ($key =~ /select/) {
                $select = $key;
            }
        }# End foreach my $key
        
        #Do here some MA::HADES Stuff
        if ($ds->{SERVICE}->{NAME} =~ /MA\/HADES/  && $ds->{DOECHO} != 1){
            if ($ds->{SERVICE}->{NAME} =~ /STATUS/){
                $ds->{SERVICE}->{NAME} =~ s/\/STATUS//;
                $self->{HADES}->{ACTION}->{TYPE} = "traceroute";
		$ds->{SERVICE}->{DOPARSE} = 1;
            }
            if (!$select){
            	my $error = "No select block found for data id: $dataid";
            	$self->{LOGGER}->error($error);
                $ds->{REQUESTMSG}->return_result_code("error.ma.parameters", 
                                                        $error, $ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{"metaref"});
                $ds->{ERROROCCUR} = 1;
                return;
            }
            if (!($ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{$select}{"startTime"}) &&
                !($ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{$select}{"endTime"})){
                	my $error = "No timespan specified!";
                	$self->{LOGGER}->error($error);
	                $ds->{REQUESTMSG}->return_result_code("error.ma.parameters", 
                                                        $error, $ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{"metaref"});
                        $ds->{ERROROCCUR} = 1;
                        return; 
            }
            #At fist get eventype from message nor from metadata
            foreach my $key (keys %{$ds->{REQUESTMSG}->{"dataIDs"}{$dataid}}){
                next if ($key eq "node" || $key eq "metaref" || $key =~ /select/
                || $key eq "ns_uri" || $key eq "ns_prefix" );
                
                    $self->{HADES}->{ACTION}->{EVENTYPE} = $key;
            }
            my $agg_ets = join ('_', @{$self->{HADES}->{ACTIONS}->{"ippm_aggregated"}});
            my $raw_ets = join ('_', @{$self->{HADES}->{ACTIONS}->{"ippm_raw"}});
            #$self->{LOGGER}->info(Dumper($self->{HADES}->{ACTION}->{EVENTYPE}));
            if ($agg_ets =~ /$self->{HADES}->{ACTION}->{EVENTYPE}/){
                $self->{HADES}->{ACTION}->{TYPE} = "ippm_aggregated";
            } elsif($raw_ets =~ /$self->{HADES}->{ACTION}->{EVENTYPE}/){
                $self->{HADES}->{ACTION}->{TYPE} = "ippm_raw";
            }
	    my $filter = $ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{$self->{HADES}->{ACTION}->{EVENTYPE}};   
            if ($$filter{"interval"}){
                $$filter{"interval"} *= 1000000;
            }
	    #$self->{LOGGER}->info(Dumper($filter));
            $self->{HADES}->{FILTER} = $filter;
	    #$self->{LOGGER}->info(Dumper($self->{HADES}->{FILTER}));
        }# End Hades stuff
        
        my $error = $self->checkParams($ds, %parameters);
        if ($error){
            $self->{LOGGER}->error($error);
            $ds->{REQUESTMSG}->return_result_code("error.common.parse_error", $ds->{SERVICE}->{NAME} . " : " . $error, $ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{"metaref"});
            $ds->{ERROROCCUR} = 1;
            return;
        }#Endf ($error)
        
        #Checks for parameterswas  ok add to parameterlist
        #Check if store parameters or service
        if (defined $parameters{'dataref'}){        	
            if ( $params->{ $parameters{'dataref'}}->{STORE}->{DOIT}){
             	$params->{$parameters{'dataref'}}->{STORE}->{PARAMS} = \%parameters;
            }
        }
        else{
        	$params->{$dataid}->{PARAMS} = \%parameters;
        }  
        
        #$self->{LOGGER}->info(Dumper($params));
        
        #do selftests
        #TODO test this part
        if($messagetype =~ /EEchoResponse/){
        	$self->{LOGGER}->debug("Perform Echo");
            my @tests = ("bwctl_command_test",
                 "bwctl_exec_test",
                 "bwctld_running_test",
                 "ntpd_running_test");
            foreach my $test (@tests){
                $self->{LOGGER}->debug("Perform test: $test");
                my ($message, $status) = $self->$test; #TODO what means self->$test
                my $et = "http://schemas.perfsonar.net/tools/admin/selftest/MP/BWCTL/$test/$status/1.0";
                $ds->return_result_code(
                $et, $message, $ds->{REQUESTMSG}->{"dataIDs"}{$dataid}{"metaref"}, $test);
            }# Emd foreach my $test 
            return #TODO what should here returned
        }#End if($messagetype =~
        
        
         
        
    }# End foreach my $dataid
    
    $ds->{SERVICE}->{DATA} = $params;
    #$self->{LOGGER}->info(Dumper($ds->{REQUESTMSG}));
        
           
}




=head2 NMWGcheckMessagetype({})

Checks the message type of a NMWG message. As parameter give the messagetype attribute of the NMWG message. 

=cut
sub NMWGcheckMessagetype{
    
    my ($self,$messagetype,$ds) = @_;
    
    if ($messagetype eq "ErrorResponse"){ #error from authentication!
        return -1;
    }    
    if ($messagetype eq "AuthNEERequest"){ #authorization rquest to dummy AS
        require perfSONAR::AS;
        $$ds->{RETURNMSG} = perfSONAR::AS::dummy();
        return -1;
    }
    if ($messagetype eq "SetupDataRequest"){
        $$ds->{REQUESTMSG}->set_message_type("SetupDataResponse");
    }
    elsif ($messagetype eq "MeasurementRequest"){
        $$$ds->{REQUESTMSG}->set_message_type("MeasurementResponse");
    }
    elsif ($messagetype eq "MetadataKeyRequest"){
        $$ds->{REQUESTMSG}->set_message_type("MetadataKeyResponse");
        
        #MetadataKeyRequest to MP are not allowed
        if ($$ds->{SERVICE}  =~ /MP/){
        	 my $errorstring = "MetadataKeyRequest to MP service is not supported";
            $self->{LOGGER}->error($errorstring);
            $$ds->{REQUESTMSG}->set_message_type("ErrorResponse");
            $$ds->{ERRMSG} = $errorstring;
            return 0;
        }
    }
    elsif ($messagetype =~ /EchoRequest/){
        $$ds->{REQUESTMSG}->set_message_type("EchoResponse");
    }      
    else {
        my $errorstring = "Unknown messagetype: $messagetype";
        $self->{LOGGER}->error($errorstring);
        $$ds->{REQUESTMSG}->set_message_type("ErrorResponse");
        $$ds->{ERRMSG} = $errorstring;
        return 0;
    }
    return 1;
    #$self->{LOGGER}->info("Messagetype: finish"); 
    #$self->{LOGGER}->info(Dumper($ds));
}

=head2 checkParams()

Checks the nmwg parameters.As value the method needs a hash of parameters which are defined by the dataIds. On success it do nothing.
Otherwise it returns an error string  

=cut
#TODO return error message if unknown parameters to client
sub checkParams{
	my ($self,$ds, %parameters) = @_;
	my (@unknown,@unsupported, $error);
    #$self->{LOGGER}->info(Dumper(%parameters));
    
    
    foreach my $par (keys %parameters){
        next if ($par eq "ns_prefix" ||
            $par eq "param_ns_prefix" ||
            $par eq "subject_ns_prefix" ||
            $par eq "subject_ns_uri" ||
            $par eq "param_ns_uri" ||
            $par eq "parameter_ID" ||
            $par eq "metaID" ||
            $par eq "address" ||
            $par eq "metadatakey");
        next if exists $ds->{"known_parameters"}{$par};
        if (exists $ds->{"unsupported_parameters"}->{$par}){
            push @unsupported, $par;            
        } else {
            push @unknown, $par;
            #$self->{LOGGER}->info(Dumper($par));
        }
        #more owamp
        if ($parameters{"output"} && !($parameters{"output"} eq "per_packet" ||
                $parameters{"output"} eq "machine_readable" ||
		$parameters{"output"} eq "summary" ||
                $parameters{"output"} eq "raw") ){
            $error = "Unknown output parameter: $parameters{output}";
            return $error;
        }        
    }# End foreach my $par
    
    #TODO
    if ($#unknown >= 0){
        $error =  "Unknown parameter(s): " . join (", ", @unknown);
        return $error;
    }

    if ($#unsupported >= 0){
        my $error =  "Unsupported parameters(s): " . join (", ", @unsupported);
        return $error;
    }
    return;
}


=head2 parseResult($datastruct_ref)
The meaurement result is stored in $$ds->{SERVICE}->{DATA}. For this this method is called with a reference to the data struct. Use the 
id field to get the specific result. Some checks are needed in this method to decide if it is a EchoRequest or a error is occured
=cut
sub parseResult{

    my ($self, $ds) = @_;
    my $ns_serivce = $$ds->{SERVICE}->{NAME};
    $ns_serivce =~ s/\///;
    my $ns = $self->{NS}->{$ns_serivce};
    
    #Set ns if MA::Hades
    if ($ns_serivce =~ /MAHADES/){
        $ns = $self->{NS}->{HADES};
    }

    my $data = $$ds->{SERVICE}->{DATA};
    my $messagetype = $$ds->{REQUESTMSG}->get_message_type();
     
    foreach my $id (keys %{$data}){
	#Hades MA params occur
	if ($$ds->{NMWG}->{HADES}->{$id}->{RESPARAMS}->{OCCURARRAY}){
            my $result_params = $$ds->{NMWG}->{HADES}->{$id}->{RESPARAMS}->{DATA};
            $$ds->{REQUESTMSG}->set_parameter_list(@$result_params);
        }
		if ($$ds->{NMWG}->{HADES}->{$id}->{RESPARAMS}->{OCCURHASH}){
            my %result_params = %{$$ds->{NMWG}->{HADES}->{$id}->{RESPARAMS}->{DATA}};
            $result_params{metadataIdRef} = $self->{HADES}->{FILTER}{"metaID"};
            #$self->{LOGGER}->info(Dumper(%result_params));
            $$ds->{REQUESTMSG}->set_parameter_hash(%result_params);
        }
        my $datalines_ref = $$ds->{SERVICE}->{DATA}->{$id}->{MRESULT};
        if ($$ds->{DOECHO}){	   	   
            my $data_hash = pop @$datalines_ref;
            my %echo = %$data_hash;
            $$ds->{REQUESTMSG}->return_result_code($echo{echocode}, $echo{echomsg},$$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"metaref"})
        }elsif ($$ds->{DOSELFTEST}){
        	my $data_hash = pop @$datalines_ref;
        	my $response_et = "http://schemas.perfsonar.net/tools/admin/selftest/";        	
        	foreach my $name (keys %{$data_hash}){
        		my $array_ref= $data_hash->{$name};
        		my $ns_selftest = "$response_et$$ds->{SERVICE}->{NAME}/$name/@$array_ref[1]/1.0";
        		$$ds->{REQUESTMSG}->return_result_code($ns_selftest,"@$array_ref[0]",$$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"metaref"},"$name");;	
        	}        	
        }elsif ($$ds->{ERROROCCUR}){
            my $et = pop @$datalines_ref;
            $$ds->{REQUESTMSG}->return_result_code($et, "@$datalines_ref",$$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"metaref"});
	    #Sometimes we need here parse result
	    if ($$ds->{SERVICE}->{DOPARSE}){
	        if ($$ds->{SERVICE}->{NAME} =~ /HADES/){
                    $self->parseHadesMA($$ds->{NMWG}->{HADES}->{STATUSDATA},$id,$ds);
               }
	    }
        }else{	
            #Hades MA need a another parse
            if ($$ds->{SERVICE}->{NAME} =~ /HADES/){
				my @res = $self->parseHadesMA($datalines_ref,$id,$ds);
				$datalines_ref = $res[0];
				$ns = $res[1];
            }
	    # Get if OWAMP the ns for summary or raw
	    my $owampoutput; 
	    $owampoutput = $$ds->{SERVICE}->{DATA}->{$id}->{OUTPUTTYPE} if defined $$ds->{SERVICE}->{DATA}->{$id}->{OUTPUTTYPE};
	    if (defined $owampoutput && $$ds->{SERVICE}->{NAME} =~ /OWAMP/ ){
		if ( $owampoutput=~ /summary/ ){
			$ns = $self->{NS}->{OWAMPSUMMARY};	
		}
	    }
            $$ds->{REQUESTMSG}->set_data_ns ($id, $ns, @$datalines_ref);

            my $storesuccess = 1;
            #Look if data should be stored by metadata
            if (defined $$ds->{SERVICE}->{DATA}->{$id}->{STORE}->{DOIT}){
                if (! $self->store($ds,$id,"META")){
                    #store was not possible
                    $storesuccess = 0                   
                }	       	
            }#ENd if (defined $$ds
            #Look if store is activated by configuration file
            if ( $$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{module_param}->{store}){
                if (! $self->store($ds,$id,"CONF")){
                    #store was not possible
                    $storesuccess = 0
                }    
            }#End f ( $$ds->{SERVICES
            
            if (! $storesuccess){
                my $et = "error.mp.store";
                my $error = $$ds->{ERRORMSG};
                $$ds->{REQUESTMSG}->return_result_code($et, $error, $$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"metaref"});
                $self->{LOGGER}->error($error);
            }	       
	   }#+End foreach my $id 
	   #$self->{LOGGER}->info(Dumper($store));
    }	
}

=head2 store()
To store the measurement data in a measurement archive this method is used. For this the {STORE}->{PARAMS} field 
in the data structure is used. To get the store parameters use the id of the measurement. This is used if store 
request is included in metadata.

Store by service configuration file is also supported. For this the parameters in:
$$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{module_param} is used. This is a hash with the information for store.
On success this method returns 1 otherwise 0. On 0 (error) $$ds->{ERRORMSG} field will be set.
=cut
sub store{
	
	my ($self, $ds, $id, $store_by) = @_;
	my $store_url = undef;
	
	#OWAMP store is acctually not supported
	#if ($$ds->{SERVICE}->{NAME}  =~ /OWAMP/ ){
	#	$$ds->{ERRORMSG} = "Store by OWAMP MP is actually not supported";
        #return 0;
	#}
	if ($store_by eq "CONF"){
		$store_url = $$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{module_param}->{store_url};
		
	}
	elsif ($store_by eq "META"){
		$store_url = $$ds->{SERVICE}->{DATA}->{$id}->{STORE}->{PARAMS}->{uri};
	}else{
        $$ds->{ERRORMSG} = "This kind of store request is not supported";
        return 0;
	}
	
	if (! $store_url){
        $$ds->{ERRORMSG} = "No store url defined in configuration file";
        return 0;
    }
    $self->{LOGGER}->debug("Storing data to SQL MA: $store_url");
    my $store_msg = $$ds->{REQUESTMSG}->clone;
    
    if (!$store_msg){
    	$$ds->{ERRORMSG} = "Store to MA failed: Could not clone storage message.";
        return 0;
    }
    
    $store_msg->set_message_type("MeasurementArchiveStoreRequest");
    my $request = perfSONAR::Request->new(
          message => $store_msg->clone,
          uri => $store_url,
	); 
	$request->send();
   
   #my $result = $response->as_string(2);
   my $et;
   my $msg;
	if ( $request->{SEND_SUCCESS} ){
		$msg = "Store was successful on SQL MA";
		$self->{LOGGER}->info($msg);
		$et = "success.mp.store";   	
   }else{
   		$msg = "Store was NOT successful on SQL MA";
		$self->{LOGGER}->error($msg);
		$et = "error.mp.store";   	
   }
    
    
    #Write success to METADATA if requestet
    if ($store_by eq "META"){
		$$ds->{REQUESTMSG}->return_result_code($et, $msg, $$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"metaref"});
    }
    return 1;	
}

sub parseHadesMA{
    my ($self, $data_obj,$id,$ds) = @_;
    my @datalines;
    my $ns = $self->{NS}->{HADES};
    
    #$self->{LOGGER}->info(Dumper($$data_obj));
    if ($$data_obj->isa("Hades::Data::IPPM_Raw")){
        $ns = $self->{NS}->{RAW};
    	my $data = $$data_obj->{data};
    	foreach my $ref (@$data) {
      		next unless (ref ($ref) eq "HASH");
      		my %data_hash;
      		$data_hash{"seqnr"} = $$ref{"seqnr"};
      		$data_hash{"senttime_sec"} = $$ref{"senttime_sec"};
      		$data_hash{"senttime_nsec"} = $$ref{"senttime_nsec"};
      		$data_hash{"recvtime_sec"} = $$ref{"recvtime_sec"};
      		$data_hash{"recvtime_nsec"} = $$ref{"recvtime_nsec"};
      		push @datalines, \%data_hash;
        }
    }elsif ($$data_obj->isa("Hades::Data::IPPM_Aggregated")){
        my $data = $$data_obj->{data};
        my $metric = $$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"select"}{"metric"};
        my $sample = $$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"select"}{"sample"};
        my $count = -1;
        
        foreach my $ref (@$data) {
            my %data_hash;
            my $time = $$ref{"time"};
            next unless $time;
            
            if ($sample){
                $count++;
                next unless $count % $sample == 0;
            }

            $data_hash{"time"} = $time; 
            
            if (!$metric || $metric eq "all" || $metric eq "owd"){
                $data_hash{"min_delay"} = $$ref{"min_owd"};
                $data_hash{"med_delay"} = $$ref{"med_owd"};
                $data_hash{"max_delay"} = $$ref{"max_owd"};
            }

            if (!$metric || $metric eq "all" || $metric eq "ipdv"){
	        $data_hash{"min_ipdv_jitter"} = $$ref{"min_ipdv"};
	        $data_hash{"med_ipdv_jitter"} = $$ref{"med_ipdv"};
	        $data_hash{"max_ipdv_jitter"} = $$ref{"max_ipdv"};
	      }

              if (!$metric || $metric eq "all" || $metric eq "lost_packets"){
      	          $data_hash{"loss"} = $$ref{"lost_packets"};
              }
              if (!$metric || $metric eq "all" || $metric eq "duplicate_packets"){
                  $data_hash{"duplicates"} = $$ref{"duplicate_packets"};
              }

              $data_hash{"sync"} = "yes";
              push @datalines, \%data_hash; 
        } #End foreach my $ref
    } #End elsif ($$data_obj->isa(
    elsif ($$data_obj->isa("Hades::Data::Traceroute")){
        $$data_obj->extract_data();
		my $eventType = $self->{HADES}->{ACTION}->{EVENTYPE};
        if ($$data_obj->isa("Hades::Data::Traceroute")){
            foreach my $timestamp (@{$$data_obj->{"timeline"}}){
                my $ref = $timestamp->{"ref"};
                next if (!defined $ref); #TODO Doesn't this ignore gaps ???
	        my $time = $timestamp->{"time"};
	        my (@hops, $hopcount);
		if ($ref >= 0) {
	            @hops = @{$$data_obj->{"traceroutes"}->[$ref]};
	            $hopcount = $#hops;
	        } else {
		    @hops = (); $hopcount = 0;
		}
		if ($eventType =~ /aggregated/){
	            my %data_hash;
	            $data_hash{"timeValue"} = $time;
	            $data_hash{"timeType"} = "unix";
	            $data_hash{"hopcount"} = $hopcount;
	            $data_hash{"routeref"} = $ref;
          	    push @datalines, \%data_hash;
		} elsif ($eventType =~ /hoplist/){
		    my $datanode = $$ds->{REQUESTMSG}->{"dataIDs"}{$id}{"node"};
	            $ns = $self->{NS}->{HOPLIST};
	            my $i = 0;
	            my $timenode = $$ds->{REQUESTMSG}->add_attribute(parent => $datanode, nodename => "commonTime",
                           type => "unix", value => $time);
		    foreach my $entry (@hops){
	                my %data_hash;
	                $data_hash{"index"} = $i;
	                $data_hash{"hopAddress"} = $entry->{"ip"};
     	                $data_hash{"type"} = "ipv4"; #TODO IPv6!
	                $data_hash{"hopHostname"} = $entry->{"name"};
            
	                $$ds->{REQUESTMSG}->add_attribute(parent => $timenode, nodename => "datum",
		                  namespace => $self->{NS}->{HOPLIST}, %data_hash);
	                $i++; 
		    }   
		}
  
            }
        }
    }#End  elsif ($data->isa("Hades::Data::Traceroute
    
    return (\@datalines,$ns);
    
}

=head2 getEventtypeforservice(string service)
For every service is a eventtpye defined. this eventtype can be get here.
to get the eventtype this function needs the service. Service can be:
	owamp : OWAMP MP, owampd or owamp2hades
	bwctl : BWCTL MP and bwctld
	iperf : for iperf tool
	hades : HADES MA
	summary : For summary
	...
	have a look to supportedEventypes hash above

The function return the full eventtype URL liek
=cut
sub getEventtypeforservice{
	my ($self, $service) = @_;
	my %module_ets = %{pop(@{$self->{"supportedEventtypes"}})};
	
	if ($service){
     	    return $module_ets{$service}; 
	}else{
	    return -1;
	}

}



1;
