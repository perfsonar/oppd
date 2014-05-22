package perfSONAR::SOAP::Fault_v1_1;
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
# - A lot more information extraction could be done here.....

# See http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383507

#NOTES
# Order and number of children of Fault element are not restricted by
# by SOAP 1.1 specification. We use XPath to get at least what we need...
# Further we ignore other children, since they are explicitly allowed by
# specification. It is not clear, whether more than one element is allowed for
# the explicitly expected element. This module simply only uses the first one
# to make parsing fail as seldom as possible.

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use XML::LibXML;

use base 'perfSONAR::SOAP::Fault';


sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($faultcode_uri, $faultcode, $faultstring,
    $faultfactor, $detail, @additional) = @_;

  my $self = {};
  bless $self, $class;

  my $ns_soap = $perfSONAR::SOAP::ns_soap11;

  # We are creating from scratch
  # -> Create container document and basic elements
  my $doc = XML::LibXML::Document->createDocument();
    #TODO version and encoding?

  $self->{dom} = $doc->createElementNS($ns_soap,"soapenv:Fault");
  $doc->setDocumentElement($self->{dom});

  # Create XPathContext with appropriate namespace:
  $self->{xpc} = XML::LibXML::XPathContext->new($self->{dom});
    #TODO Is it really save to create context once at the beginning?
  $self->{xpc}->registerNs('soap',$ns_soap);


  # faultcode and faultstring are obligatory.
  # Also the elements have to be created here, since other methods expect them
  # to exist already.
  # Btw: namespace of faultcode is optional, because Envelope namespace is
  # default.
  unless ($faultcode) {
    croak "Missing faultcode";
  }
  $self->{dom}->addNewChild(undef,"faultcode");
  $self->faultcode($faultcode_uri,$faultcode);
  unless ($faultstring) {
    croak "Missing faultstring";
  }
  $self->{dom}->addNewChild(undef,"faultstring");
  $self->faultstring($faultstring);

  # Now the optional elements:
  if ($faultfactor) {
    $self->faultfactor($faultfactor);
  }
  if ($detail) {
    $self->detail($detail);
  }
  #TODO Are these "other" elements really useful?
  if (@additional) {
    $self->additional(@additional);
  }

  return $self;
}

sub from_dom {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($dom) = @_;

  my $self = $class->SUPER::from_dom($dom);
  bless $self, $class;

  # Check for correct namespace/version:
  my $ns_soap =  $self->{dom}->namespaceURI();
  unless ($ns_soap eq $perfSONAR::SOAP::ns_soap11) {
    croak "Invalid namespace for SOAP Fault element";
  }
  # Create XPathContext with appropriate namespace
  $self->{xpc} = XML::LibXML::XPathContext->new($self->{dom});
    #TODO Is it really save to create context once at the beginning?
  $self->{xpc}->registerNs('soap',$ns_soap);

  # Now check for necessary elements by retrieving them via our own methods:
  $self->faultcode;
  $self->faultstring;

  return $self;
}

# Default namespace uri is http://schemas.xmlsoap.org/soap/envelope/
sub faultcode {
  my $self = shift;
  my ($ns_uri,$code) = @_;

  # There should really always be a faultcode element and we need it anyway.
  # -> We can already retrieve it here
  my $faultcode = $self->{xpc}->findnodes("faultcode")->get_node(1)
    or croak "Missing faultcode element below Fault element";
  unless ($ns_uri || $code) {
    # No arguments => return current content
    my $content = $faultcode->textContent
      or croak "Empty faultcode element in SOAP Fault";
      #TODO Is textContent really correct?
    $content =~ m/(.+):(.+)/ or croak "Invalid faultcode in SOAP Fault";
    my $ns_prefix = $1;
    my $ns_uri = $faultcode->lookupNamespaceURI($ns_prefix)
      or croak "Cannot determine namespace URI for SOAP Fault faultcode";
    my $code = $2;
    return $ns_uri, $code;
  }

  unless ($code) {
    croak "faultcode needs at least a text string as second parameter";
  }
  $ns_uri ||= $perfSONAR::SOAP::ns_soap11;

  # Set code
  if ($faultcode->hasChildNodes) {
    $faultcode->removeChildNodes;
  }
  my $ns_prefix = $faultcode->lookupNamespacePrefix($ns_uri);
  unless ($ns_prefix) {
    $ns_prefix = "nscode";
    $faultcode->setNamespace($ns_uri,$ns_prefix,0);
  }
  #$faultcode->addChild(
  #  $faultcode->ownerDocument->createTextNode("$ns_prefix:$code")
  #);
  $faultcode->appendTextNode("$ns_prefix:$code");
  return $self;
}

sub faultstring {
  my $self = shift;
  my ($string) = @_;

  # There should really always be a faultstring element and we need it anyway.
  # -> We can already retrieve it here
  my $faultstring = $self->{xpc}->findnodes("faultstring")->get_node(1)
    or croak "Missing faultstring element below Fault element";
  unless ($string) {
    # No arguments => return current content
    my $content = $faultstring->textContent
      or croak "Empty faultstring element in SOAP Fault";
      #TODO Is textContent really correct?
    return $content;
  }

  # Set string
  if ($faultstring->hasChildNodes) {
    $faultstring->removeChildNodes;
  }
  #$faultstring->addChild(
  #  $faultstring->ownerDocument->createTextNode($string)
  #);
  $faultstring->appendTextNode($string);
  return $self;
}

# TODO Should we check the factor itself somehow? It should be a URI, but that
#      might lead to unnecessary parsing errors.
sub faultfactor {
  my $self = shift;
  my ($factor) = @_;

  unless ($factor) {
    # No arguments => return current content
    my $faultfactor = $self->{xpc}->findnodes("faultfactor")->get_node(1)
      or return;
    return $faultfactor->textContent;
      #TODO Is textContent really correct?
  }

  # Set factor
  my $faultfactor;
  if ($faultfactor = $self->{xpc}->findnodes("faultfactor")->get_node(1)) {
    if ($faultfactor->hasChildNodes) {
      $faultfactor->removeChildNodes;
    }
  } else {
    # We have to create the faultfactor element first:
    $faultfactor = $self->{dom}->ownerDocument->createElementNS(
      undef, "faultfactor"
    );
    $self->{dom}->insertAfter(
      $faultfactor, $self->{xpc}->find("faultstring")->get_node(1)
    );
  }
  #$faultfactor->addChild(
  #  $faultfactor->ownerDocument->createTextNode($factor)
  #);
  $faultfactor->appendTextNode($factor);
  return $self;
}

sub detail {
  my $self = shift;

  unless (@_) {
    return @{$self->{xpc}->findnodes("detail/*")};
  }

  # Set detail
  my $detail;
  if ($detail = $self->{xpc}->findnodes("detail")->get_node(1)) {
    if ($detail->hasChildNodes) {
      $detail->removeChildNodes;
    }
  } else {
    # We have to create the detail element first:
    $detail = $self->{dom}->ownerDocument->createElementNS(
      undef, "detail"
    );
    $self->{dom}->insertAfter(
      $detail, $self->{xpc}->find("faultstring")->get_node(1)
    );
  }
  foreach (perfSONAR::SOAP::Message::_prepare_nodes(@_)) {
    $detail->appendChild($_);
  }
  return $self;
}

#TODO
# IMPORTANT:
# This method is only adding additional elements and NOT deleting already
# existing additional elements! But don't use it anyway!    
sub additional {
  my $self = shift;

  foreach (perfSONAR::SOAP::Message::_prepare_nodes(@_)) {
    $self->{dom}->appendChild($_);
  }
}

1;
