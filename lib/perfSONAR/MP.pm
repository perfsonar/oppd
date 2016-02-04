package perfSONAR::MP;
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

perfSONAR::MP - Main class for all measurement poibt (MP) services. 

=head1 DESCRIPTION

This is the base class for all measurement point classes like 
bwctl or owamp. It holds all main methods to start a measurement
use the runMeasuremt method. For detail information see below.It 
is important that all measurement point classes like BWCTL, which 
uses this class as base class, should have this 3 methods: 
run() - to start the measurement point
createCommand() - to create a command from the parameters
parse_result() - to parse the measurement result data

for details see the examples BWCTL and OWAMP 

=cut

use strict;
use warnings;


#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 0.52;

use Log::Log4perl qw(get_logger);
use IPC::Run qw( run timeout start finish pump);
#use IO::Pty;
use POSIX ":sys_wait_h";
use DateTime;
use base qw(perfSONAR::Esmond::Client);
use base qw(perfSONAR::Echo);
use base qw(perfSONAR::Selftest);

=head1 Methods:

=head2 createCommandLine(%parameters)

Every service which works as a measurement point (MP) should have (overrite) this method. 
This method will be called from the method MP::runMeasurement(). It called with a hash 
which contains the iotions with the regarding value. Build from this a array, which calls
the command. Dont include the tool name like bwctl or owping. Return as result this array.
=cut
sub createCommandLine{
	my $self = shift;
	return undef;
}

=head2 parse_result($datastruct_ref, $id_of_measurement)

After the measurement the method MP::runMeasurement() will call this method. So include this method to your MP service.
This method will get a reference to the data structure. As second value it will get the identification from the measurement.
Use this to get the result data from the measurement. Use:
        
        my $result = $$ds->{SERVICE}->{DATA}->{$id}->{MEASRESULT};
        
This is a string. Parse it to the specific form. Build a array of hashes with the values. Return this array so the main method can use it.

=cut
sub parse_result{
	my $self = shift;
	return undef;
}

=head2 run($reference_to_datastructucre)

This is the starting point of a MP. So include this method to your service to make runable. Only a reference to the 
data strucre is on start given. Save this and call the main method runMeasurement() with no argument. Use the following 
template for this:
    sub run{
        my ($self, $ds) = @_;
    
        $self->{DS} = $ds;
        $self->runMeasurement();
    }
=cut

=head2 new()

The constructor is called withoud a parameter.
=cut
sub new{
	my ($class,%module_param) = @_;
    my $self = {};
    $self->{LOGGER} = get_logger(__PACKAGE__);
    if (exists $module_param{command}){
    	$self->{COMMAND} = $module_param{command};
	$self->{MAINSERVICE} = $module_param{service};
    	my $ret = `which $self->{COMMAND} 2>/dev/null`;
    	if ( length $ret <= 0 ){
        	my @errmsg;
        	push @errmsg, "ERROR:";
        	push @errmsg, "command:", $self->{COMMAND} ;
        	push @errmsg, "not found. Please install it!";
        	$self->{LOGGER}->error("@errmsg");
        	die "@errmsg";
    	}
    }
    $self->{MODPARAM} = \%module_param;
    $self->{ESMONDCLIENT} = new perfSONAR::Esmond::Client 
    bless $self, $class;
    return $self;
}

=head2 runMeasurement({})

This function can be used to start a measurement point (MP). It use a data struct. 
The PARAMS field should be set. The result of the measurement is stored 
in the MPRESULT field of data struct. The type is array. On error 
occurnes the field is set to "ERROR".

=cut
sub runMeasurement{
	my ($self) = @_;
	my $logger = get_logger("perfSONAR::MP" );
	my $ds = $self->{DS};
	my $pass;
	
	#Get tool for commandline
    #my $tool = $$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{tool};
    my $tool = $self->{COMMAND};
	
	my $data = $$ds->{SERVICE}->{DATA};
	#$self->{LOGGER}->info(Dumper($data));
	foreach my $id (keys %{$data}){
		
		my @commandline = $self->createCommandLine(
		      %{$data->{$id}->{PARAMS}});
        
		if ($commandline[0] eq "ERROR") {
            $$ds->{ERROROCCUR} = 1;
            push @commandline,"error.$tool.mp";
            $$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@commandline;
            return;
        }
        #Start commandline
        #first check if tool is available
        my $ret = `which $tool 2>/dev/null`;
        if ( length $ret <= 0 ){
        	$$ds->{ERROROCCUR} = 1;
        	my $et = "error.$tool.mp";
        	my @errmsg;
        	push @errmsg, "ERROR:";
        	push @errmsg, "command:", $tool;
        	push @errmsg, "not found";
        	$self->{LOGGER}->error("@errmsg");
        	push @errmsg, $et;
            $$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@errmsg;
            return;
        }
        
        $self->{LOGGER}->info("Service: $$ds->{SERVICE}->{NAME} called with command: $tool @commandline");
        
        #Define pipes
        my ($in, $out, $err);
        
        #Define call
        my @call = @commandline;
        unshift @call, $tool;
        
        my $h = start (\@call, \$in, \$out, \$err);
        #my $h = start (\@call, '<pty<', \$in, '>pty>', \$out, '2>', \$err);
        while (1){
            pump $h;
            if ($err =~ /passphrase/){
                $in = "$pass\n";
                $err = "";
            }
            elsif ($err ne "\n"){
                last;
            }
        }#End  while (1)
        my $out_tmp = $out;
        my $err_tmp = $err;
        finish $h;

        if (!$out){
            $$ds->{SERVICE}->{DATA}->{$id}->{MEASRESULT}  = "$err";
        }
        else{
        	$$ds->{SERVICE}->{DATA}->{$id}->{MEASRESULT} = "$out";
        }
        #parse the result
        my @mresult = $self->parse_result($ds,$id);
        #$self->{LOGGER}->info(Dumper(@mresult));
        $$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@mresult;
        $$ds->{SERVICE}->{DATA}->{$id}->{OUTPUTTYPE} = $self->{OUTPUTTYPE};
	}#End foreach my $id
		
	#On success write to log
	if ($$ds->{ERROROCCUR}){
		$logger->info("The measurement was NOT successfull for service: $$ds->{SERVICE}->{NAME}");
	}
	else{
		$logger->info("The measurement was successfull for service: $$ds->{SERVICE}->{NAME}");
		$self->store_result();
	}
	   
}

sub store_result{
    my $self = shift;

    #Get store parameters
    my %esmond_params =  (
			url =>  $self->{MODPARAM}->{esmond_url},
			username => $self->{MODPARAM}->{esmond_auth_username},
			apikey => $self->{MODPARAM}->{esmond_auth_apikey},
			ca_file => $self->{MODPARAM}->{esmond_ca_certificate_file},
			store => $self->{MODPARAM}->{esmond_store},
			);

    if ( ! $esmond_params{store} ){
       return; #esmond storage not active
    }

    $self->connect_storage(\%esmond_params);
    $self->set_metadata_general($self->{ESMOND});
    $self->set_metadata_service();

}

1;
