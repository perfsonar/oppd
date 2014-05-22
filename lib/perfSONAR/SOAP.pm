package perfSONAR::SOAP;
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
# - There are a lot more feature of SOAP that could be implemented...
#   (http://www.w3.org/TR/soap/)
#   E.g. the "application/soap+xml" media type
#   (http://www.ietf.org/rfc/rfc3902.txt)

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use XML::LibXML;


our $ns_soap11 = 'http://schemas.xmlsoap.org/soap/envelope/';
our $ns_soap12 = 'http://www.w3.org/2003/05/soap-envelope';
our %version2ns = (
  1.1 => $ns_soap11,
  1.2 => $ns_soap12,
);
our %ns2version = (
  $ns_soap11 => "1.1",
  $ns_soap12 => "1.2",
);


1;
