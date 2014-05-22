package perfSONAR::AS;
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

use NMWG::Message;

sub dummy {

  #read in template:
  my $authmsg = NMWG::Message->new();
  $authmsg->parse_xml_from_file("$FindBin::RealBin/../etc/Auth_response.xml");

  if (!$authmsg){
    $authmsg->parse_xml_from_file("/etc/oppd/Auth_response.xml");
  }

  return $authmsg;
}

1;
