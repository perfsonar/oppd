package perfSONAR::Auth;
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

use strict;
use warnings;

use Carp;
#DEBUG
#use Data::Dumper;
#/DEBUG

use perfSONAR qw(print_log);

## Authentication: send Auth-request to server, then proceed.
# do the following:
# - get <nmwg:parameter name="SecurityToken"> from header
# - check <wsse:Security> element
# - read in template fill in <nmwg:parameter name="SecurityToken">
# - add $header to message
# - send message to AS
# - wait for response from AS (timeout)
# - parse response from AS for <nmwg:eventType>XXXXXXX</nmwg:eventType>
# - either respond with error result (see <nmwg:eventType>XXXXXXX</nmwg:eventType>)
# - or: go on with normal operation (adding a result code with
#   <nmwg:eventType>XXXXXXX</nmwg:eventType>)
#
# TODO:
# - parse error description from AS (necessary?)
# - authenticate based on messagetype!! (-> different structure, is this useful?
#   better: athentication based on service!)

  my $saml_token = "http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV1.1";
  my $x509_token = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3";
  my $AS_uri = "http://homer.rediris.es:8080/perfSONAR-AS/services/AuthService"; 


sub authenticate {
  my $soapmsg = shift;
  my $reqmsg =shift;
  my $as_uri = shift;
  
  my $token;

  print_log("info", "Authentication:\n");
  if ((!defined ($soapmsg)) || !(UNIVERSAL::isa($soapmsg,"perfSONAR::SOAP::Message"))){
    croak "No valid message given!\n";
  }
  if ((!defined ($as_uri)) || UNIVERSAL::isa($as_uri,"URI")){
    #croak;
    $as_uri = $AS_uri; #get default 
  }
  if (!$soapmsg->header){
    my $errorstring = "No authentication information in SOAP header!";
    print_log("error", "$errorstring\n");
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("error.authn.no_sectoken", "$errorstring", "message");
    return $reqmsg;
  } else {
    $token = check_token($soapmsg->header);
  }
  if (!(defined $token)) {
    my $errorstring = "Authentication token in header is missing!";
    print_log("error", "$errorstring\n");
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("error.authn.no_sectoken", "$errorstring", "message");
    $soapmsg->clear_header;
    return $reqmsg;
  }
  if ($reqmsg->get_message_type eq "AuthNEERequest"){ #authorization request to dummy AS
    return $reqmsg;
  }
  if ($reqmsg->get_message_type eq "EchoRequest"){ #EchoRequest ping unauthorized
    return $reqmsg;
  }
  my $authmsg = create_authmsg($token);
  #clone header TODO: necessary??
  my @header = clone_header($soapmsg->header);
  #my @header = $soapmsg->header;
  #send message to server:
  my $soap_auth_msg = perfSONAR::SOAP::Message->new(
    body => $authmsg->as_dom,
    uri => $AS_uri,
    header => \@header
  );
  #DEBUG
=cut
  my $timestamp = time;
  my $file = "soap_request-$timestamp.xml";
  open (FH, ">", "$file");
  print FH $soap_auth_msg->as_string;
  close FH;
  #/DEBUG
=cut
  my $userAgent = perfSONAR::SOAP::HTTP::UserAgent->new;
  my $auth_request = perfSONAR::SOAP::HTTP::Request->new(message => $soap_auth_msg);
  #DEBUG print "auth_reqeust\n";
  #DEBUG print $auth_request->as_string . "\n";
  #DEBUG print "auth_request end\n";
  my $auth_response = $userAgent->request($auth_request);

  my $soap_auth_response = $auth_response->soap_message;
  #DEBUG
=cut
  my $timestamp = time;
  my $file = "soap_response-$timestamp.xml";
  open (FH, ">", "$file");
  print FH $soap_auth_response->as_string;
  close FH;
  #/DEBUG
=cut



  unless ($auth_response->is_success) {
    #HTTP error
    my $code = $auth_response->code();
    my $description = $auth_response->message();
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("error.authn.server", "HTTP error: $code, $description", "message");
    $soapmsg->clear_header;
    return $reqmsg;
  }
  $soapmsg->clear_header;
  if ($soap_auth_response->is_fault){
    #SOAP error
    my $description = $soap_auth_response->{fault}->as_string;
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("error.authn.server", "SOAP error: $description", "message");
    return $reqmsg;
  }

  my $auth_nmwg = NMWG::Message->new( ($soap_auth_response->body)[0] );
  #print "DEBUG: Return message: \n" . $auth_nmwg->as_string . "\n";
  if (!$auth_nmwg){
    my $errorstring = "Authentication failed: No response from Authentication Service";
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("error.authn.server", "$errorstring", "message");
    return $reqmsg;
  }
  
  my $event_node = ($auth_nmwg->{dom}->getElementsByLocalName("eventType"))[0]; 
  my $auth_event = $event_node->textContent;
  if ($auth_event ne "success.as.authn") { #some error occured
    #find description of error
    my $desc_node = ($auth_nmwg->{dom}->getElementsByLocalName("datum"))[0];
    my $description = $desc_node->textContent;
    my $errorstring = "Authentication failed on server: $description";
    $reqmsg->set_message_type("ErrorResponse");
    $reqmsg->return_result_code("$auth_event", "$errorstring", "message");
    return $reqmsg;
  }
  #else just proceed
  my $returnstring = "Authentication succeded";
  $reqmsg->return_result_code("$auth_event", "$returnstring", "message");
}



sub check_token {
  my @header = shift;
  foreach my $entry (@header){
    if (UNIVERSAL::isa($entry,"XML::LibXML::Node")){
      if ($entry->localname =~ /Security/){
        my @sec_elems = $entry->getChildNodes();
        foreach my $sec_elem (@sec_elems){
          next unless (defined $sec_elem->localname);
          if ($sec_elem->localname =~ /BinarySecurityToken/){
            return $x509_token;
            #return $saml_token;
          } elsif ($sec_elem->localname =~ /Assertion/){
            return $saml_token;
            #return $x509_token;
          }
        }
      }
    }
  }
  return undef;
}

  
sub create_authmsg {
  my $token = shift;

  #read in template:
  my $authmsg = NMWG::Message->new();
  $authmsg->parse_xml_from_file("$FindBin::RealBin/../etc/Auth_request.xml");
  if (!$authmsg){
    $authmsg->parse_xml_from_file("/etc/oppd/Auth_request.xml");
  }

  #set token
  my $tokennode = ($authmsg->{dom}->getElementsByLocalName("parameter"))[0];
  if ($tokennode) {
    $tokennode->appendText("$token");
  }
  
  return $authmsg;
}

sub clone_header {
  my @orig_header = shift;
  my @new_header;
  foreach my $entry (@orig_header){
    if (UNIVERSAL::isa($entry,"XML::LibXML::Node")){
      my $new_entry = $entry->cloneNode(1);
      unshift @new_header, $new_entry;
    }
  }
  return @new_header;
}

1;
