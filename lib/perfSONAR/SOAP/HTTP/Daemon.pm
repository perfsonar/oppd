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
# - From http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383529
#   "In case of a SOAP error while processing the request, the SOAP HTTP server
#   MUST issue an HTTP 500 "Internal Server Error" response and include a SOAP
#   message in the response containing a SOAP Fault element (see section 4.4)
#   indicating the SOAP processing error."
#   Is this also similar for 1.2? Despite that it makes sense in any case ;)

use strict;
use warnings;

#DEBUG
#use Data::Dumper;
#/DEBUG

use Carp;

use HTTP::Daemon;

use base 'HTTP::Daemon';

#TODO TODO fill me !!!
