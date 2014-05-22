package perfSONAR::MA;
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

=head1 NAME

perfSONAR::MA - Main class for all measurement archiev (MA) services. 

=head1 SYNOPSIS

use base  qw(perfSONAR::MA);

=head1 DESCRIPTION

This is the main class for all MAs.
=cut

use strict;
use warnings;

#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 0.53;

use Log::Log4perl qw(get_logger);
use base qw(perfSONAR::Echo);


=head2 new()

The constructor is called withoud a parameter.
=cut
sub new{
    my ($class,%module_param) = @_;
    my $self = {};
    $self->{LOGGER} = get_logger(__PACKAGE__);
    $self->{MODPARAM} = \%module_param;
    $self->{MAINSERVICE} = $module_param{service};
    bless $self, $class;
    return $self;
}

1;

