package perfSONAR::SOAP::HTTP::Request;
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

use HTTP::Request;
use perfSONAR::SOAP::Message;

use base 'HTTP::Request';


# More or less a wrapper around HTTP::Request->new, setting a lot of defaults
# useful for SOAP requests.
# Parameters are set as hash to provide better flexibility and concentrate more
# on SOAP requirements.
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %p = (
    method => "POST",
    uri => undef,
    # The HTTP(!) header
    # If header is a HTTP::Headers object, this object will be used and all
    # SOAP specific defaults will NOT be set. If header is a plan array
    # reference, a HTTP::Headers object will be created, all SOAP specific
    # defaults will be set and finally the values from the array will be set.
    header => undef,
    # The SOAP message:
    message => undef,
    @_
  );

  my $header;
  my @header_defaults = (
    SOAPAction    => '""',
    pragma        => 'no-cache',
    cache_control => 'no-cache',
    accept        => 'application/soap+xml, application/dime, multipart/related, text/*',
  );
  if (defined $p{header}) {
    croak("Bad header argument") unless ref $p{header};
    if (ref($p{header}) eq "ARRAY") {
      $header = HTTP::Headers->new(@header_defaults, @{$p{header}});
    } else {
      $header = $header->clone;
    }
  } else {
    $header = HTTP::Headers->new(@header_defaults);
  }

  if (defined $p{message}) {
    unless (UNIVERSAL::isa($p{message},'perfSONAR::SOAP::Message')) {
      croak "Parameter \"message\" to perfSONAR::SOAP::HTTP::Request " .
        "must be of type perfSONAR::SOAP::Message";
    }
    if (!defined $p{uri}) {
      $p{uri} = $p{message}->uri;
    }
  }

  my $self = $class->SUPER::new($p{method}, $p{uri}, $header);

  $self->protocol("HTTP/1.0");

  bless $self, $class;

  if (defined $p{message}) {
    $self->soap_message($p{message},1);
  }

  return $self;
}

# This method behaves like HTTP::Request::content, but expects one mandatory
# parameter of type perfSONAR::SOAP::Message instead of a string.
# This is a one-way method! You can only set a SOAP message!
# The URI of this object will be set to the URI of the perfSONAR::SOAP::Message
# object, if it is set.
sub soap_message {
  my $self = shift;
  my ($message, $do_not_set_uri) = @_;

  unless (UNIVERSAL::isa($message,'perfSONAR::SOAP::Message')) {
    croak "perfSONAR::SOAP::HTTP::Request->soap_message has to be called" .
          "with one parameter of type perfSONAR::SOAP::Message";
  }
  my $content = $message->as_string;
  $self->content_length(length($content));
  if (!$do_not_set_uri && defined $message->uri) {
    $self->uri($message->uri);
  }
  return $self->content($content);
}


1;
