package perfSONAR::SOAP::HTTP::Response;
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

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use HTTP::Response;

use base 'HTTP::Response';


# This method behaves like HTTP::Response::content, but will croak if an
# argument is passed!
# This is a one-way method! You can only get a SOAP message from it, not set
# it!
sub soap_message {
  my $self = shift;
  my ($message) = @_;

  if (@_) {
    carp "No parameters allowed for soap_message"
      if $^W;
  }

  return perfSONAR::SOAP::Message->from_http_response($self);
}


1;
