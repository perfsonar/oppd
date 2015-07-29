package perfSONAR::MP::BWCTL;
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

perfSONAR::MP::BWCTL

=head1 DESCRIPTION

This class runs measurementds for BWCTL. It use as base class the MP class. All BWCTL specific 
definitions done here. This class has no concstructor defined. Ituse the new method from MP class

=cut


use strict;
use warnings;


#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 1.0;

use Log::Log4perl qw(get_logger);
use base qw(perfSONAR::MP);
use  perfSONAR::Tools;

=head2 run()

The run method starts a bwctl measurement and use the runMeasurement()
method from perfSONAR::MP. To start the measurement a data struct as 
input is needed. For example to start a bwctl measurement:

1. $bwctl = perfSONAR::MP::BWCTL->new();
2.$ds = perfSONAR::DataStruct->new($uri, $message);
3. $bwctl->run();

=cut
sub run{
	my ($self, $ds) = @_;
	$self->{LOGGER} = get_logger(__PACKAGE__);
	$self->{DS} = $ds;
	$self->runMeasurement();
}


=head2 createCommandLine({})

To start a measurement with bwctl a commandline expression is needed. 
This expression will be created here. As input a hash parameter of bwctl options are needed.
On success it will return a array with bwctl options and parameters. On errpr it 
will return an array with ("ERROR,error message as string).

=cut
sub createCommandLine{
    my ($self,%parameters) = @_;
    my @commandline;
    my $errormsg;
        
    unless ($parameters{"src"} || $parameters{"dst"}) {
        $errormsg = "Neither source nor destination ip address specified.";
        $self->{LOGGER}->error($errormsg);
        return "ERROR", $errormsg;
    }
    
    if ($parameters{"src"} eq $parameters{"dst"}) {
        $errormsg = "Source ip address equal to destination ip address.";
        $self->{LOGGER}->error($errormsg);
        return "ERROR", $errormsg;
    }

    #check parameters to be correct input:
    #TODO test this condition
    foreach my $param (keys %parameters){
        next if ($param eq "param_ns_prefix" ||
             $param eq "metaID" ||
             $param eq "subject_ns_prefix" ||
             $param eq "parameter_ID" ||
             $param eq "param_ns_uri" ||
             $param eq "subject_ns_uri");
        next if ($param eq "src" || $param eq "dst");
        if ($param eq "login" || $param eq "password"){
            unless ($parameters{$param} =~ /^\w+$/){
                $errormsg = "Invalid login/password string specified.";
                $self->{LOGGER}->error($errormsg);
                return "ERROR", $errormsg;
            }
            next;
        }#End if ($param eq "login
        if ($param eq "TOS"){
            unless ($parameters{$param} =~ /^\d+|0x\d+$/){
                $errormsg = "Invalid TOS string specified.";
                $self->{LOGGER}->error($errormsg); 
                return "ERROR", $errormsg;
            }
            next;
        }#End if ($param eq "TOS
        if ($param eq "protocol"){
            unless ($parameters{$param} =~ /^udp$/i || $parameters{$param} =~ /^tcp$/i){
                $errormsg = "Unknown protocol: $parameters{protocol}";
                $self->{LOGGER}->error($errormsg);
                return "ERROR", $errormsg;
            }
            next;
        }#End if ($param eq "protocol
        unless ($parameters{$param} =~ /^\d+$/){
            $errormsg = "Invalid value specified for $param.";
            $self->{LOGGER}->error($errormsg);
            return "ERROR", 
        }
    }#End foreach my $param
    #End parameter check
    
    #check what is the local interface
    if ( perfSONAR::Tools->checkIPisLocal($parameters{src}) == 1){
        $parameters{local_interface} = $parameters{src};
    }elsif ( perfSONAR::Tools->checkIPisLocal($parameters{dst}) == 1){
	$parameters{local_interface} = $parameters{dst};
    }
    
    #Now create Command
    push @commandline , "-s" , $parameters{"src"}; 
    push @commandline , "AE", "AESKEY" if($parameters{"login"});
    push @commandline , $parameters{login} if($parameters{"login"});
    push @commandline , "-c", $parameters{dst};
    push @commandline , "AE", "AESKEY" if($parameters{"login"});
    push @commandline , $parameters{login} if($parameters{"login"});  
    push @commandline , "-i", $parameters{interval} if($parameters{"interval"});
    push @commandline , "-t", $parameters{duration} if($parameters{"duration"});
    push @commandline , "-w", $parameters{windowSize} if($parameters{"windowSize"});
    push @commandline , "-u" if ($parameters{"protocol"} && $parameters{"protocol"} =~ /^udp$/i);
    push @commandline , "-l", $parameters{bufferSize} if($parameters{"bufferSize"});
    push @commandline , "-b", $parameters{bandwidth} if($parameters{"bandwidth"});
    push @commandline , "-B", $parameters{local_interface} if($parameters{"local_interface"});
    push @commandline , "-S", $parameters{TOS} if($parameters{"TOS"});
    
    return @commandline;   
    
}


=head2 parse_result({})

After a measurement call the result message of the tool should be parsed.
This method will be called from the MP class. The measurement result 
ub $$ds->{PARAMS}->{$id}->{MEASRESULT}will be used. On success it returns 
a array. The elements of the array are hashes. On error the $$ds->{ERROROCCUR}
will be set to 1. For this $$ds->{RETURNMSG} will be set to the error string.

=cut
sub parse_result {
  
  my ($self, $ds, $id) = @_;
  my $result = $$ds->{SERVICE}->{DATA}->{$id}->{MEASRESULT};
  my @result = split(/\n/, $result);
  my @datalines;
  my $time = time;
  
  
  foreach my $resultline (@result){
    next unless  ($resultline =~
        /(\d+\.\d+\s*\-\s*\d+\.\d+)\s+sec\s+(\d+\.?\d*)\s+(\w+)\s+(\d+\.?\d*)\s+(\w+\/\w+)/);

    my %data_hash;
    
    $data_hash{"timeType"} = "unix";
    $data_hash{"timeValue"} = $time;
    $data_hash{"interval"} = $1;
    $data_hash{"numBytes"} = $2;
    $data_hash{"numBytesUnits"} = $3;
    $data_hash{"value"} = $4;
    $data_hash{"valueUnits"} = $5;
    push @datalines, \%data_hash;
  }
  if($#datalines < 0){
    #no data -> something wrong, write result as error description:
    $datalines[0]="BWCTL Error:";
    my $errorstring = "@result";
    $errorstring =~ s/usage.*$//;
    $$ds->{ERROROCCUR} = 1;
    $self->{LOGGER}->error($errorstring);
    push @datalines, @result;
    push @datalines,"error.mp.bwctl";        
  }    
  return @datalines;
} 


=head2 selftest()
Define here the steps for the selftest
=cut
sub selftest{
	my ($self, $ds, $id) = @_;
	my $params = $$ds->{SERVICE}->{DATA};
	my @datalines;
	
	foreach my $id (keys %{$params}){
		my %data_hash;
		
		$data_hash{'bwctl_command_test'} = [$self->checkTool("bwctl")];
		$data_hash{"bwctld_running_test"} = [$self->checkToolisrunning("bwctld")];
		$data_hash{"ntpd_running_test"} = [$self->checkToolisrunning("ntpd")];
	
		push @datalines, \%data_hash;
		$$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@datalines
	}#End foreach
	return;
}

1;
