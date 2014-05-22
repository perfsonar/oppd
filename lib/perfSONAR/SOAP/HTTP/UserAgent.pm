package perfSONAR::SOAP::HTTP::UserAgent;
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

use LWP::UserAgent;
use perfSONAR::SOAP::HTTP::Response;
use base 'LWP::UserAgent';


our $timeout = 5000;


# More or less a wrapper around LWP::UserAgent->new
# You can use the same parameters as for LWP::UserAgent->new
sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = $class->SUPER::new(
    timeout => $timeout, # our own default here
    @_
  );
  bless $self, $class;
}

sub request {
  my $self = shift;
  return bless($self->SUPER::request(@_), 'perfSONAR::SOAP::HTTP::Response');
}


1;
