package perfSONAR;
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

#DEBUG
use Data::Dumper;
#/DEBUG

use strict;
use warnings;

BEGIN {
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  use Exporter;
  #@ISA = qw(Exporter SOAP::Server::Parameters);
  @ISA = qw(Exporter);

  # if using RCS/CVS, this may be preferred
  #$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
  @EXPORT      = qw();          # Symbols to autoexport (:DEFAULT tag)
  @EXPORT_OK   = qw(print_log %services); # Symbols to export on request
  %EXPORT_TAGS = qw();          # Define names for sets of symbols
                                # eg: TAG => [ qw(name1 name2) ],
}

use version;
our $VERSION = 1.0;

use Carp;

use Log::Log4perl qw(get_logger);



=head1 NAME

perfSONAR

=head1 DESCRIPTION

Use this to have a starting point to use all availible services.

=head1 Methods

=cut

#This are the globals
our %services = ();
my $echo_et = "http://schemas.perfsonar.net/tools/admin/echo/2.0";

#TODO
#Replace complete NMWG from this handler
#to make it more flexible
#replace by DataStruct


=head2    handle_request(uri,requestMessage)

 starts all requested EventTypes included in the request.
 Need two parameters which are uri and requestMessage. 
 The parameters should have the following types:
 
  uri STRING =>  complette link for the service
 
  requestMessage
 
 returns t
=back

=cut
sub handle_request {
  
    my ($self, $ds) = @_;
    my $logger = get_logger(__PACKAGE__);
    my @datalines;
    
    #look if service is availible
    if (! $ds->{SERVICES}->{$ds->{SERVICE}->{NAME}}){
    	my $errormsg = "Requested service: $ds->{SERVICE}->{NAME} is not availible";
    	$logger->error($errormsg);
    	$ds->{ERROROCCUR} = 1;
    	$datalines[0]="Service request Error:";
    	push @datalines, $errormsg;
    	push @datalines, "error.common.service_not_availible";
    	$ds->{SERVICE}->{DATA}->{1}->{MRESULT}  = \@datalines;
    	$ds->{$ds->{DSTYPE}}->parseResult(\$ds);
    	return;
    }
    
    if ($ds->{DOECHO}){
    	$ds->{SERVICES}->{$ds->{SERVICE}->{NAME}}->{handler}->handle_echo_request(\$ds);
    }elsif ($ds->{DOSELFTEST}){
    	$ds->{SERVICES}->{$ds->{SERVICE}->{NAME}}->{handler}->selftest(\$ds);
    }else{
        $ds->{SERVICES}->{$ds->{SERVICE}->{NAME}}->{handler}->run(\$ds);
    }
    $ds->{$ds->{DSTYPE}}->parseResult(\$ds);
  
}

#TODO this method should be implemented in a other modul
#it should be independent from NMWG
#Replace NMWG by DataStruct
sub sendReceive {
  my %p = (
    message => undef,
    host => "localhost",
    port => "8090",
    endpoint => "/",
    uri => "",
    soapheader => "", #TODO TODO noch nicht fertig und kein String!
    @_
  );

  my $uri = $p{uri} || "http://$p{host}:$p{port}$p{endpoint}";
  my $body = $p{message}->as_dom;

  # Message is NMWG::Message
  my $message = perfSONAR::SOAP::Message->new(
    body => $body,
    uri => $uri
  );
  # Modify SOAP header using $message or set via "new" call directly

  my $userAgent = perfSONAR::SOAP::HTTP::UserAgent->new;
  my $request = perfSONAR::SOAP::HTTP::Request->new(message => $message);

  my $response = $userAgent->request($request);
  unless ($response->is_success) {
    # HTTP error
    #my $code = $response->code();
    #my $message = $response->message();
    carp $response->status_line if $^W; # "<code> <message>"
    return;
  }

  my $soap_message = $response->soap_message;
  if ($soap_message->is_fault) {
    carp "TODO" if $^W;
    return;
  }

  my $nmwg_message = NMWG::Message->new( ($soap_message->body)[0] );
  #TODO This should perhaps be NMWG::Message->from_soap_message($soap_message);

  return $nmwg_message;
}

1;
