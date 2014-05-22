package perfSONAR::SOAP::Fault_v1_2;
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

# See http://www.w3.org/TR/soap12-part1/#soapfault

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
  my ($Values, $Reasons, $Node, $Role, $Detail) = @_;
=cut
$Value = [
  "VersionMismatch"|"MustUnderstand"|"DataEncodingUnknown"|"Sender"|"Receiver",
  *:*, ....
];
$Reason = {
  <lang> => <text>,
  ....
};
$Node = <uri>;
$Role = "http://www.w3.org/2003/05/soap-envelope/role/next" | "next" |
  "http://www.w3.org/2003/05/soap-envelope/role/none" | "none" |
  "http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver" |
    "ultimateReceiver";
$Detail = [ <nodelist> ];
=cut

  my $self = {};
  bless $self, $class;
  return $self;
}

#TODO Remove this 1.1 dummy API and "enhance" 1.1 to 1.2
sub faultcode {
  my $self = shift;
  if (@_) {
    return "SOAP 1.2 Fault not supported", "SOAP 1.2 Fault not supported";
  } else {
    return $self;
  }
}
sub faultstring {
  my $self = shift;
  if (@_) {
    return "SOAP 1.2 Fault not supported";
  } else {
    return $self;
  }
}
sub faultfactor {
  my $self = shift;
  if (@_) {
    return "SOAP 1.2 Fault not supported";
  } else {
    return $self;
  }
}
sub detail {
  my $self = shift;
  if (@_) {
    return  XML::LibXML->new->parse_string("<error>SOAP 1.2 Fault not supported</error>")->documentElement;
  } else {
    return $self;
  }
}


1;
