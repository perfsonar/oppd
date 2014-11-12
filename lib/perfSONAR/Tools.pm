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
use Net::DNS;

#DEBUG
#use Data::Dumper;
##DEBUG


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

sub getIPbyhostname{
    my ($self, $hostname) = @_;
    my $logger = get_logger(__PACKAGE__);
    #$logger->info("Get host name: $hostname");

    #Check hostname is cname
    my $cname = $self->checkHostnameisCname($hostname);
    #$logger->info("CNAME: $cname");
    if (defined $cname){ 
        $hostname = $cname;
    }

    my $res   = Net::DNS::Resolver->new;
    my $reply = $res->search($hostname);

    if ($reply) {
        foreach my $rr ($reply->answer) {
            if ( $rr->type eq 'AAAA'){
                return "ipv6", $rr->address; 
            }elsif ( $rr->type eq "A"){
                return "ipv4", $rr->address;
            }
        }
    }
    return;
}

sub checkHostnameisCname{
    my ($self, $hostname) = @_;
    my $logger = get_logger(__PACKAGE__);
    my $res   = Net::DNS::Resolver->new;
    my $reply = $res->search($hostname);

    if ($reply) {
        foreach my $rr ($reply->answer) {
            if ('CNAME' eq $rr->type){
                return $rr->cname;;
            }
        }
    }
    return undef;
}

sub checkIPisLocal{
    my ($self, $ip) = @_;
    my $logger = get_logger(__PACKAGE__);
    my $islocal = 0;
    my @localIps = $self->getLocalInterfaces();
    if ( grep( /^$ip$/, @localIps ) ) {
        $islocal = 1;
    }
    return $islocal;
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
