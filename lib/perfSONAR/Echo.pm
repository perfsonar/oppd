package perfSONAR::Echo;
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

perfSONAR::Echo

=head1 DESCRIPTION

This is the main class for Echo requests. All services use this class as a base
class. This class hasnt a constructor. All services use the  handle_echo_request
method.
=cut

#DEBUG
use Data::Dumper;
#/DEBUG

use strict;
use warnings;
use Log::Log4perl qw(get_logger);

my $echo_et = "http://schemas.perfsonar.net/tools/admin/echo/2.0";
my $selftest_et = "http://schemas.perfsonar.net/tools/admin/selftest/1.0";
my $response_et = "http://schemas.perfsonar.net/tools/admin/selftest/";

=head2 handle_echo_request()
 This method is used from the services to return a status response for the service
=cut

sub handle_echo_request{
	
	my ($self, $ds) = @_;
	my $logger = get_logger("perfSONAR::Echo" );
	$logger->info("Start Echo");
	my $params = $$ds->{SERVICE}->{DATA};
	my @datalines;
	
    foreach my $id (keys %{$params}){   
    
        #echo request
        my %data_hash;
        $logger->info("Reply to EchoRequest ping");
        $data_hash{'echocode'} = "success.echo";
        $data_hash{'echomsg'} = "Service: $$ds->{SERVICE}->{NAME} is ready for call";
        push @datalines, \%data_hash;
        $$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@datalines
    }    
}

=head2 selftest($tool,$servicetype)

to start the selftest for the service start  this method. Override this method
in the service.  
=cut
sub selftest{
	my $self = shift;
	return undef;	
}


1;
