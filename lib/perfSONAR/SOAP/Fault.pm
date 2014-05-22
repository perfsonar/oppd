package perfSONAR::SOAP::Fault;
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

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use XML::LibXML;


sub new {
  #TODO Make building a SOAP Fault simple. But which version to choose?
  #TODO Extract version from Namespaces and load corresponding module
  #     Is this really useful. Is the benefit worth doing such complicated
  #     things?
  croak "Direct call on perfSONAR::SOAP::Fault not supported (yet).\n";
  #my $this = shift;
  #my $class = ref($this) || $this;
  #my ($source) = @_;
  #my $self = {};
  #bless $self, $class;
  #return $self;
}

sub from_dom {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($dom) = @_;

  my $self = {};
  bless $self, $class;

  if (UNIVERSAL::isa($dom,"XML::LibXML::Element")) {
    $self->{dom} = $dom;
  } elsif (UNIVERSAL::isa($dom,"XML::LibXML::Document")) {
    $self->{dom} = $dom->documentElement();
  } else {
    croak "First argument to perfSONAR::SOAP::Fault->from_dom " .
      "must be of type XML::LibXML:Element or XML::LibXML::Document\n";
  }

  # Do we have a SOAP Fault element here?
  unless ($self->{dom}->nodeName =~ m/:Fault$/) {
    croak "Not a valid SOAP fault: Missing element Fault";
  }

  return $self;
}

sub from_string {
  #TODO Do we really need this feature? Should it rather be added somehow
  #     to new method(s).
  croak "perfSONAR::SOAP::Fault cannot be created from string source (yet).\n";
  #my $this = shift;
  #my $class = ref($this) || $this;
  #my ($xml) = @_;
}


1;
