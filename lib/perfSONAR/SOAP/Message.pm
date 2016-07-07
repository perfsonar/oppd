package perfSONAR::SOAP::Message;
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
# - There are a lot more parsing and checking could be implemented...

#NOTES
# - Regarding SOAP Faults this module enforces some rules:
#   - There is only one fault allowed in a message
#   - For SOAP 1.2 there is explicitly no other element allowed if the message
#     contains a Fault element. For SOAP 1.1 this is unsure!
#     It is only explicitly requested if SOAP is used for RPC (See "Using SOAP
#     for RPC, http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383533)
#     If a message contains a fault, other body elements that might exist are
#     not deleted, but ignored! This should make it possible to stay
#     compatible with "strange" SOAP 1.1 messages that we might have to parse.
#     But: It is NOT possible to create such a message using this module or
#     add children to the Body element of a Fault message.
#
# Important keys of $self hash:
# dom: The root (aka. Envelope) element. NOT necessarily the Document root.
# xpc: An XPathContext with context node set to $self->{dom} and the namespace
#      prefix "soap" set to the correct namespace URI.
# fault: The corresponding SOAP::Fault object, if message contains a fault.
#        Otherwise the key doesn't exist at all.

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use URI;
use XML::LibXML;
use XML::LibXML::NodeList;

use perfSONAR::SOAP;
use perfSONAR::SOAP::Fault;
use perfSONAR::SOAP::Fault_v1_1;
use perfSONAR::SOAP::Fault_v1_2;


# All parameters optional! Header and body are empty by default. Version
# defaults to "1.1".
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %p = (
    header => undef, body => undef, fault => undef,
    uri => undef, version => "1.1",
    @_
  );

  my $self = {};
  bless $self, $class;

  # Set version
  $self->version($p{version});
    # We don't care about versions from header or body!
  my $ns_soap = $perfSONAR::SOAP::version2ns{$self->version};

  # Set URI
  $self->uri($p{uri}) if defined $p{uri};

  # We are creating from scratch
  # -> Create container document and basic elements
  my $doc = XML::LibXML::Document->createDocument();
    #TODO version and encoding?

  $self->{dom} = $doc->createElementNS($ns_soap,"soapenv:Envelope");
  $doc->setDocumentElement($self->{dom});

  # Create XPathContext with appropriate namespace:
  $self->{xpc} = XML::LibXML::XPathContext->new($self->{dom});
    #TODO Is it really save to create context once at the beginning?
  $self->{xpc}->registerNs('soap',$ns_soap);

  # We always need a Body element:
  $self->{dom}->addNewChild($ns_soap,"Body");

  # Now we add the (optional) head
  if (defined $p{header}) {
    unless (ref($p{header}) eq "ARRAY") {
      croak "Parameter \"header\" of perfSONAR::SOAP::Message->new must be " .
        "a list of XML::LibXML::Node objects";
    }
    if (@{$p{header}}) {
      $self->header($p{header});
    }
  }

  # Fault needs more thinking:
  if (defined $p{body}) {
    if (defined $p{fault}) {
      croak 
        "perfSONAR::SOAP::Message::new needs either body or fault, not both!";
    }
    # Body, no fault
    $self->body($p{body});
  } elsif (defined $p{fault} && $p{fault}->isa('perfSONAR::SOAP::Fault')) {
    # No body, but fault
    $self->fault($p{fault}); 
  }

  return $self;
}

sub from_dom {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($dom,$uri) = @_;

  my $self = {};
  bless $self, $class;

  if (UNIVERSAL::isa($dom,"XML::LibXML::Element")) {
    $self->{dom} = $dom;
  } elsif (UNIVERSAL::isa($dom,"XML::LibXML::Document")) {
    $self->{dom} = $dom->documentElement();
  } else {
    croak "First argument to perfSONAR::SOAP::Message->from_dom " .
      "must be of type XML::LibXML:Element or XML::LibXML::Document\n";
  }

  # Do we have a SOAP envelope?
  unless ($self->{dom}->nodeName =~ m/:Envelope$/) {
    croak "Not a valid SOAP message: Missing element Envelope";
  }

  # First determine SOAP version and create XPathContext with appropriate
  # namespace:
  my $version;
  my $ns_soap = $self->{dom}->namespaceURI;
  if ($ns_soap eq $perfSONAR::SOAP::ns_soap11) {
    $version = "1.1";
  } elsif ($ns_soap eq $perfSONAR::SOAP::ns_soap12) {
    $version = "1.2";
  } else {
    #TODO SOAP Fault: VersionMismatch
    croak "Not a valid SOAP message: Unknown namespace";
  }
  $self->{xpc} = XML::LibXML::XPathContext->new($self->{dom});
    #TODO Is it really save to create context once at the beginning?
  $self->{xpc}->registerNs('soap',$ns_soap);

  # Now check for the necessary body element:
  unless ($self->{xpc}->findnodes("soap:Body")->size == 1) {
    croak "Not a valid SOAP message: Missing element Body";
  }

  # Set uri and version
  $self->uri($uri) if defined $uri;
  $self->version($version); # We don't care about versions from header or body!

  # Handle faults
  if (
    my @faults = $self->{xpc}->findnodes("soap:Body/soap:Fault")
  ) {
    my $fault_src = shift @faults;
    if (@faults) {
      croak "More than one Fault element not allowed in SOAP Message";
    }
    $self->fault($fault_src);
  }

  #TODO Check for "invalid" elements?

  return $self;
}

sub from_string {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($source,$uri) = @_;

  croak "No XML source to parse" unless $source;
  my $parser = XML::LibXML->new(ext_ent_handler => sub { return ""; });
  my $dom;
  eval {
    $dom = $parser->parse_string($source);
  };
  if ($@){
    #TODO Make me a special Exception!
    croak "Error parsing message: $@";
  }
  #TODO Is the following really needed, or is already implicitly handled above?
  unless (UNIVERSAL::isa($dom,"XML::LibXML::Document")) {
    croak "First argument to perfSONAR::SOAP::Message->from_libxml " .
      "must be a valid XML string\n";
  }
  return $class->from_dom($dom,$uri);
}

sub from_http_request {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($request) = @_;
  my $self = {};

  unless (UNIVERSAL::isa($request,"HTTP::Request")) {
    croak "First and only argument to "
      . "perfSONAR::SOAP::Message->from_http_request"
      . "  must be of type HTTP::Request\n";
  }

  my $content = $request->content;
  my $uri = $request->uri;
  #DEBUG print "HTTP request URI: $uri\n";
  #DEBUG print "HTTP request content:\n$content\n";
  return $class->from_string($content,$uri);
    #TODO use SOAPAction / application/soap+xml action for uri ???
}

sub from_http_response {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($response) = @_;
  my $self = {};

  unless (UNIVERSAL::isa($response,"HTTP::Response")) {
    croak "First and only argument to "
      . "perfSONAR::SOAP::Message->from_http_response"
      . "  must be of type HTTP::Response\n";
  }

  my $content = $response->content;
  my $uri = $response->base;
  #DEBUG print "HTTP response URI: $uri\n";
  #DEBUG print "HTTP response content:\n$content\n";
  return $class->from_string($content,$uri);
    #TODO use SOAPAction / application/soap+xml action for uri ???
}


# Converts a list to DOM nodes (e.g. body or header content).
# Parameters are a mixed list of:
# - Array reference (will be flattened)
# - XML::LibXML::Node (will be included directly)
# - XML::LibXML::NodeList (Nodes in list will be included directly)
# - String (will be parsed as XML Document and root Element will be included)
sub _prepare_nodes {
  my @result = ();  # the result list
  my @sources = (); # the flattened intermediate step
  foreach my $entry (@_) {
    if (UNIVERSAL::isa($entry,"XML::LibXML::NodeList")) {
      push @sources, $entry->get_nodelist;
    } elsif (ref($entry) eq "ARRAY") {
      push @sources, @{$entry};
    } else {
      push @sources, $entry;
    }
  }
  foreach my $entry (@sources) {
    if (UNIVERSAL::isa($entry,"XML::LibXML::Document")) {
      # Special case: Although Document is also a Node, appendChild is not
      # working. This should always work:
      push @result, $entry->documentElement;
    } elsif (UNIVERSAL::isa($entry,"XML::LibXML::Node")) {
      push @result, $entry;
    } else {
      my $parser = XML::LibXML->new(ext_ent_handler => sub { return ""; });
      my $dom;
      eval {
        $dom = $parser->parse_string($entry);
      };
      if ($@){
        croak "Error parsing XML source: $@";
      }
      push @result, $dom->documentElement();
    }
  }
  return @result;
}

# No parameter: Header will be returned as list of XML::LibXML::Node.
sub header {
  my $self = shift;

  unless (@_) {
    return @{$self->{xpc}->findnodes("soap:Header/*")};
  }

  # Set header
  my $header;
  if ($header = $self->{xpc}->findnodes("soap:Header")->get_node(1)) {
    if ($header->hasChildNodes) {
      $header->removeChildNodes;
    }
  } else {
    # We have to create the Header element first:
    $header = $self->{dom}->ownerDocument->createElementNS(
      $self->{dom}->namespaceURI(), "Header"
    );
    $self->{dom}->insertBefore(
      $header, $self->{xpc}->findnodes("soap:Body")->get_node(1)
    );
  }
  foreach (_prepare_nodes(@_)) {
    $header->appendChild($_);
  }
  return $self;
}

sub clear_header {
  my $self = shift;

  my $header;
  if ($header = $self->{xpc}->findnodes("soap:Header")->get_node(1)) {
    if ($header->hasChildNodes) {
      $header->removeChildNodes;
    }
  } 
  return $self;
}
  
# No parameter: Body will be returned as list of XML::LibXML::Node.
# If one of the parameters is a Fault element, all other elements are ignored
# and the message becomes a Fault message.
sub body {
  my $self = shift;

  unless (@_) {
    return undef if exists $self->{fault};
    return @{$self->{xpc}->findnodes("soap:Body/*")};
  }

  my @nodes = _prepare_nodes(@_);

  # Check whether one of the nodes is a Fault element.
  # If so, we will ignore all others and use $self->fault to turn message
  # into a Fault message! We will use only the first Fault element and ignore
  # all other.
  foreach my $node (@nodes) {
    next unless $node->nodeName =~ m/:Fault$/;
    next unless $node->namespaceURI eq
                $perfSONAR::SOAP::version2ns{$self->version};
    $self->fault($node);
    return $self;
  }

  # Set body
  my $body = $self->{xpc}->findnodes("soap:Body")->get_node(1);
  if ($body->hasChildNodes) {
    $body->removeChildNodes;
  }
  foreach (@nodes) {
    $body->appendChild($_);
  }
  delete $self->{fault} if exists $self->{fault}; # Now we have a correct body!

  return $self;
}

# This internal sub is the simple way to set a SOAP Fault. It sets the
# SOAP fault that is already in the message...
# It only works with a DOM node as parameter and does neither import this node
# nor put it "to the right place".
sub _fault {
  my $self = shift;
  my $source = shift;

  if ($self->{version} eq "1.1") {
    $self->{fault} = perfSONAR::SOAP::Fault_v1_1->from_dom($source);
  } elsif ($self->{version} eq "1.2") {
    $self->{fault} = perfSONAR::SOAP::Fault_v1_2->from_dom($source);
  } else {
    croak "Cannot determine version of SOAP message";
  }
  return $self;
}

sub fault {
  my $self = shift;
  my $source = shift;

  if (!defined($source)) {
    return $self->{fault};
  }

  if (UNIVERSAL::isa($source,'perfSONAR::SOAP::Fault')) {
    if (
      ($source->isa('perfSONAR::SOAP::Fault_v1_1') && ($self->version eq "1.2"))
      ||
      ($source->isa('perfSONAR::SOAP::Fault_v1_2') && ($self->version eq "1.1"))
    ) {
      croak "Version of SOAP Fault not matching version of SOAP Message";
    }
    $self->{fault} = $source;
  } elsif (UNIVERSAL::isa($source,'XML::LibXML::Node')) {
    $self->_fault($source);
  } else {
    croak "Invalid parameter for perfSONAR::SOAP::Message->fault";
  }

  # Now add fault to Body element (deleting all other elements!)
  my $body = $self->{xpc}->findnodes("soap:Body")->get_node(1);
  if ($body->hasChildNodes) {
    $body->removeChildNodes;
  }
  $body->appendChild($self->{fault}->{dom});

  return $self;
}

# Only for convenience
sub is_fault {
  my $self = shift;

  return exists $self->{fault};
}

sub uri {
  my $self = shift;
  my $uri = shift;
  if (!defined($uri)) {
    return $self->{uri};
  } elsif (UNIVERSAL::isa($uri,"URI")) {
    $self->{uri} = $uri;
  } elsif (my $u = URI->new($uri)) {
    unless (UNIVERSAL::isa($u,"URI")) {
      croak "Invalid URI: $uri\n";
    }
    $self->{uri} = $u;
  } else {
    croak "Invalid URI: $uri";
  }
  #TODO Check $uri further?
  return $self;
}

sub uri_string {
  my $self = shift;
  my $uri = shift;
  if (!defined($uri)) {
    return unless defined $self->{uri};
    return $self->{uri}->as_string;
  } else {
    $self->uri($uri);
  }
  return $self;
}

# Does NOT convert a message from 1.1 to 1.2 or vice versa!
# This is difficult (e.g. regarding Faults), but might be added in the
# future...
sub version {
  my $self = shift;
  my $version = shift;
  if (!defined($version)) {
    return $self->{version};
  } elsif ($version eq "1.1") {
    $self->{version} = "1.1";
  } elsif ($version eq "1.2") {
    $self->{version} = "1.2";
  } else {
    croak "Unknown SOAP version: $version";
  }
  return $self;
}

sub as_string {
  my $self = shift;
  return $self->{dom}->toString;
}


1;
