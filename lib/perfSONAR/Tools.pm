package perfSONAR::Tools;
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

use Socket qw(inet_ntoa);;
use Log::Log4perl qw(get_logger);
use Sys::Hostname::Long;

=head1 NAME

perfSONAR::Tools

=head1 DESCRIPTION
This module includes some useful methods which are used in other methos of perfSONAR.

=head1 Methods

=head2 getLocalInterfaces()

Returns the ip addresses of the local interfaces.

=cut

sub getLocalInterfaces {
    my @ret_interfaces = ();

    open(IFCONFIG, "/sbin/ifconfig |");
    my $is_eth = 0;
    while(<IFCONFIG>) {
        if (/Link encap:([^ ]+)/) {
            if (lc($1) eq "ethernet") {
                $is_eth = 1;
            } else {
                $is_eth = 0;
            }
        }
        next if (not $is_eth);

        if (/inet \w+:(\d+\.\d+\.\d+\.\d+)/) {
            push @ret_interfaces, $1;
        } elsif (/inet6 \w+: (\d*:[^\/ ]*)(\/\d+)? .*:Global/) {
            push @ret_interfaces, $1;
        }
    }
    close (IFCONFIG);
    return @ret_interfaces;
}


sub getallIPsbyhostname{
    my ($self, $hostname) = @_;
    my $packed_ip = gethostbyname("www.perl.org");
    my $ip_address;
   if (defined $packed_ip) {
      $ip_address = inet_ntoa($packed_ip);
    }
    return $ip_address;
}


sub hostnameislocal{
    my ($self, $hostname) = @_;
    my $logger = get_logger(__PACKAGE__);
    my $islocal = 0;
    my $localhost = hostname_long;
    if ( $localhost eq $hostname){
        $islocal = 1
    }
   
    return $islocal;
}
1;
