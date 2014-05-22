package perfSONAR::Selftest;
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

perfSONAR::Selftest - For doing selftests in different services 

=head1 DESCRIPTION

This class hold all methods for doing selftest. Selftest is apart if the echo request
so the main method selftest() is in class Eco. Use overriding of this method in the
service to define the selftest. Every meth 

=cut

use strict;
use warnings;

#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 0.52;

use Log::Log4perl qw(get_logger);

=head1 Methods:

=head2 checkTool($tool)
looks if $tool is on system availible
=cut
sub checkTool{
	my ($self,$tool) = @_;
	my $message;
	my $status = "error";
	my $command = $tool;
	my $commandpath = `which $command`;
	chomp ($commandpath);
	if (!(-e "$commandpath")){
		$message = "Service tool $command not found!";
	} else {
		if (!( -x "$commandpath")){
			$message = "Service tool $command not executable!";
		} else {
			$message = "Service tool $command found and is executable.";
			$status = "success";
		}
	}	
	return ($message, $status);
}

=head2 checkToolisrunning($tool)
Looks if a tool for example bwctld is running
=cut
sub checkToolisrunning{
	my ($self,$tool) = @_;
	my $status = "error";
	my $message;
	my @ps_output = `ps auxw |grep $tool`;
	my $isrunning = undef;
	while (my $elem = pop @ps_output){
			next if $elem =~ /grep/;
		$isrunning = 1;
	}
	if ($isrunning){
		$message = "Service $tool is running.";
		$status = "success";
	} else {
		$message = "Service $tool not running! ";
	}
	return ($message, $status);
}
1;