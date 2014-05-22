package perfSONAR::Request;
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

perfSONAR::Request

=head1 DESCRIPTION

Use this class to send messages to different services for example LS (Loolup Service) or 
SQL MA (stroring data). 

=head1 Methods

=cut

#DEBUG
use Data::Dumper;
#/DEBUG

use Log::Log4perl qw(get_logger);
use perfSONAR::SOAP::HTTP::UserAgent;
use perfSONAR::SOAP::HTTP::Request;

my $nmwgr = "http://ggf.org/ns/nmwg/result/2.0/";

=head2    new(message,uri)
Use this constructor to setup the class in following way:

	my $request = perfSONAR::Request->new(
          message => $message->clone,
          uri => $url,
    );
    
    where:
     
  	uri (STRING) =>  complette link for the service for example:
  					 http://host_to_service.net:8080/geant2-java-sql-ma/services/MeasurementArchiveService  					 
 
  message (perSONAR::NMWG) => A perfSONAR NMWG message which is to send to a service
 
 returns: Instance of class Request
=back

=cut
sub new{
	my $class = shift;
	my %p = (
		message => undef,
		host => "localhost",
		port => "8090",
		endpoint => "/",
		uri => "",
		soapheader => "", #TODO TODO noch nicht fertig und kein String!
		@_
	);
    my $self = {};
    $self->{LOGGER} = get_logger(__PACKAGE__);
    $self->{SENDURL} = $p{uri} || "http://$p{host}:$p{port}$p{endpoint}";
	$self->{SENSMSG} = $p{message}->as_dom;
	$self->{SEND_SUCCESS} =0;
	bless $self, $class;
	
    return $self;    
}

=head2    send()
To start a request you must call this method. It use the service point and message which are given 
to new method. After request it checks the response if it was successfully or not. 

call: $request->send();

=cut
sub send { 
	my ($self) = @_;
	
	# Message is NMWG::Message
	my $url = $self->{SENDURL};
	my $message = perfSONAR::SOAP::Message->new(
    	body => $self->{SENSMSG},
    	uri => $url
	);

	# Modify SOAP header using $message or set via "new" call directly	
	my $userAgent = perfSONAR::SOAP::HTTP::UserAgent->new;
	my $request = perfSONAR::SOAP::HTTP::Request->new(message => $message);

	$self->{LOGGER}->debug("Sending request to: $url");
	my $response = $userAgent->request($request);
	unless ($response->is_success) {
		# HTTP error
		#my $code = $response->code();
		#my $message = $response->message();
		my $errmsg =  $response->status_line; # if $^W; # "<code> <message>";
		$self->{LOGGER}->error($errmsg);
		return;
	}

	my $soap_message = $response->soap_message;
	if ($soap_message->is_fault) {
		$self->{LOGGER}->error("There was an failure on sending request");
		return;
	}

	$self->{RESPONSE_MSG} = NMWG::Message->new( ($soap_message->body)[0] );
	$self->{DATUMSTRING} = ($self->{RESPONSE_MSG}->{dom}->getElementsByTagNameNS("$nmwgr", "datum"))[0]->textContent;
	#TODO This should perhaps be NMWG::Message->from_soap_message($soap_message);
	
	$self->checkResponse();

  
}

=head2    checkResponse()
This method checks response message if error occur or not. It sets respne_error to true if error occur.
Check this in calling method. and print out the error message in response_error_msg. Actually it only check NMWG messages.
=cut
sub checkResponse{
	
	my ($self) = @_;
	my $message = NMWG::Message->new();
	
	my ($errorstring, $metaid) = $self->{RESPONSE_MSG}->parse_all;
	if($errorstring){
		$self->{LOGGER}->error($errorstring);
	}
	
	my $eventtype;	
	
	foreach my $meta (keys %{$self->{RESPONSE_MSG}->{"metadataIDs"}}){
		next if ($meta eq "serviceLookupInfo");
		
		$eventtype = $self->{RESPONSE_MSG}->{"metadataIDs"}{$meta}{"eventType"};
		if ($eventtype =~ /success/){
			$self->{LOGGER}->info("Requested service returned $eventtype");
			$self->{SEND_SUCCESS} =1;
		} elsif ($eventtype =~ /register/){
			$self->{LSKEY} = $self->{RESPONSE_MSG}->{"metadataIDs"}{$meta}{"key"}{"lsKey"};
			$self->{LOGGER}->info("successfully registered service with key $key");
			$self->{SEND_SUCCESS} =1;
		} elsif ($eventtype =~ /error/){
			my $datumstring = $self->{DATUMSTRING};
			$self->{LOGGER}->error("A error occured sending request with error: $eventtype $datumstring");
		}			
		
  }# End  foreach
  
}

1;