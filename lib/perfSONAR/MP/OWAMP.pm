package perfSONAR::MP::OWAMP;
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

perfSONAR::MP::OWAMP

=head1 DESCRIPTION

This class runs measurementds for OWAMP. It use as base class the MP class. All OWAMP specific 
definitions done here. This class has no concstructor defined. Ituse the new method from MP class

=cut


use strict;
use warnings;


#DEBUG
use Data::Dumper;
#DEBUG

use version;
our $VERSION = 1.0;

use Log::Log4perl qw(get_logger);
use base qw(perfSONAR::MP);
use POSIX;
use perfSONAR::Tools;

my $scale = 2**32;

=head2 run()


The run method starts a OWAMP measurement and use the runMeasurement()
method from perfSONAR::MP. To start the measurement a data struct as 
input is needed. For example to start a OWAMP measurement:

1. $owamp = perfSONAR::MP::OWAMP->new();
2.$ds = perfSONAR::DataStruct->new($uri, $message);
3. $owamp->run();

=cut
sub run{
    my ($self, $ds) = @_;
    $self->{LOGGER} = get_logger(__PACKAGE__);
    $self->{DS} = $ds;
    
    $self->runMeasurement();
}


=head2 createCommandLine({})

To start a measurement with owamp a commandline expression is needed. 
This expression will be created here. As input a hash parameter of owamp options is needed.
On success it will return a array with owamp options and parameters. On errpr it 
will return an array with ("ERROR,error message as string).

=cut
sub createCommandLine{
    my ($self,%parameters) = @_;
    my @commandline;
    my $errormsg;
    my $ds = $self->{DS};

    #store parameters for this measurement
    $self->{PARAMS} = \%parameters;
    
    #$self->{LOGGER}->info(Dumper(%parameters));
    my $srcdst_swapped = 0;
    my $srcislocal = perfSONAR::Tools->checkIPisLocal($parameters{src});
    my $dstislocal = perfSONAR::Tools->checkIPisLocal($parameters{dst});
    #$self->{LOGGER}->info(" Src is local: $srcislocal Dst is local: $dstislocal");
    if ( $srcislocal == 0 && $dstislocal == 1 ){
        #$self->{LOGGER}->info("Changin S option");
        my $newsrc = $parameters{src};
        my $newdst = $parameters{dst};
        $parameters{src} = $newdst;
        $parameters{dst} = $newsrc;
        $srcdst_swapped = 1;
    }

    #ESMOND info
    $self->{ESMOND}{subject_type} =  "point-to-point";
    $self->{ESMOND}{source} =  $parameters{src};
    $self->{ESMOND}{destination} =  $parameters{dst};
    $self->{ESMOND}{measurement_agent} =  $parameters{src};
    if (defined  $parameters{"tool"} ) { $self->{ESMOND}{tool_name} = "bwctl/$parameters{tool}" }  else { $self->{ESMOND}{tool_name} = "bwctl/owping" };
    if (defined  $parameters{"bucket_width"} ) { $self->{ESMOND}{sample_bucket_width} = $parameters{bucket_width} }  else { $self->{ESMOND}{sample_bucket_width} = "0.0001" };
    $self->{ESMOND}{ip_transport_protocol} = "udp";
       
    push @commandline, "-S" , $parameters{src} if($parameters{"src"});
    push @commandline, "-c" , $parameters{count} if $parameters{count};
    push @commandline, "-L" , $parameters{timeout} if $parameters{timeout};
    #TODO HOW to 
    push @commandline, "-s" , $parameters{size} if $parameters{size};
    push @commandline, "-H" , $parameters{PHB} if $parameters{PHB};
    push @commandline, "-D", $parameters{DSCP} if $parameters{DSCP};
    push @commandline, "-i", $parameters{wait} if  $parameters{wait};
    push @commandline, "-E", $parameters{enddelay} if $parameters{enddelay};
    push @commandline, "-z", $parameters{startdelay} if $parameters{startdelay};
    push @commandline, "-b", $parameters{bucket_width} if $parameters{bucket_width};
    if ( $parameters{intermediates} ) { 
        push @commandline, "-N", $parameters{intermediates};
	if ($parameters{intermediates} >= $parameters{count} ){
		$self->{intermediates} = 1;
	}else{
		my $mod_res = ceil( $parameters{count} / $parameters{intermediates});
	        $self->{intermediates} = $mod_res;
		
		#Let us calculate wait time to start measurement every minute
		my $dt = DateTime->now;
		my $waittime = 60 - $dt->second;
		push @commandline, "-z", $waittime;
	}
    } else {
        $self->{intermediates} = 1;
    }
    #Look for the output type
    if ($parameters{"output"} && $parameters{"output"} eq "summary"){
    	$self->{OUTPUTTYPE} =  "summary";
    }
    elsif ($parameters{"output"} && ($parameters{"output"} eq "machine_readable")){
    	push @commandline, "-M";
    	$self->{OUTPUTTYPE} =  "machine_readable";
    }
    elsif ($parameters{"output"} && ($parameters{"output"} eq "raw")){
    	push @commandline, "-R";
    	$self->{OUTPUTTYPE} =  "raw"; 
    }
    elsif ($parameters{"output"} ){
    	#unknown output type
    	$errormsg = "You choose a unknown output type: $parameters{output}.";
        $self->{LOGGER}->error($errormsg);
        return "ERROR", $errormsg, "error.mp.owamp";    	
    }
    else{
    	#No output type defined
    	push @commandline, "-R";
        $self->{OUTPUTTYPE} =  "raw";
    }
    
    push @commandline, "-P", $parameters{portrange} if $parameters{portrange};
    
    push @commandline, "-a" if($parameters{"percentile"});
    $self->get_owd_filename();
    if ( $srcdst_swapped == 1){
       if ($self->{OUTPUTTYPE} eq "raw"){
           push @commandline, "-F", $self->{OWD_FILE};
      }else{
          push @commandline, "-f";
      }
          $self->{ESMOND}{source} =  $parameters{dst};
          $self->{ESMOND}{destination} =  $parameters{src};
    }else{
        if($parameters{"one_way"} && ($parameters{"one_way"} eq "from")){
            if ($self->{OUTPUTTYPE} eq "raw"){
                push @commandline, "-F", $self->{OWD_FILE};
                $self->{ESMOND}{source} =  $parameters{dst};
                $self->{ESMOND}{destination} =  $parameters{src};
            }else{
                push @commandline, "-f";
            }
        }elsif($parameters{"one_way"} && ($parameters{"one_way"} eq "to")){
            if ($self->{OUTPUTTYPE} eq "raw"){
                push @commandline, "-T", $self->{OWD_FILE};
            }else{
                push @commandline, "-t";
            }
        }else{
             if ($self->{OUTPUTTYPE} eq "raw"){
                push @commandline, "-T",  $self->{OWD_FILE};
            }else{
                push @commandline, "-t";
            }
        }
    }
    
    #Append destination
    if ($parameters{"dst"} ){
    	if ($parameters{"port"} ){
            my $dst = "$parameters{dst}:$parameters{port}";
            push @commandline, $dst;
    	}
    	else{
    		push @commandline, $parameters{"dst"};
    	}  
    }
    else{
    	$errormsg = "No destination address specified.";
        $self->{LOGGER}->error($errormsg);
        return "ERROR", $errormsg, "error.mp.owamp";
    }
    
    #Check the command
    #$self->{LOGGER}->info(Dumper($$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{module_param}));
    my $countlimit = $$ds->{SERVICES}->{$$ds->{SERVICE}->{NAME}}->{module_param}->{countlimit};
    if (int($parameters{"count"}) >int($countlimit)){
    	$errormsg = "count parameter greater than $countlimit is not allowed. Please change it in your request.";
    	return "ERROR", $errormsg;
    }
    #$self->{LOGGER}->info(Dumper($countlimit));
    
    return @commandline;
    
}


=head2 parse_result({})

After a measurement call the result message of the tool should be parsed.
This method will be called from the MP class. The measurement result 
in $$ds->{PARAMS}->{$id}->{MEASRESULT}will be used. On success it returns 
a array. The elements of the array are hashes. On error the $$ds->{ERROROCCUR}
will be set to 1. For this $$ds->{RETURNMSG} will be set to the error string.

=cut
sub parse_result {
  
    my ($self, $ds, $id) = @_;
    my $result = $$ds->{SERVICE}->{DATA}->{$id}->{MEASRESULT};
    my @result = split(/\n/, $result);
    my $time = time;
    my @datalines = ();
    my $recTimeiszero = 0;
   
    #$self->{LOGGER}->info("@result");    
 
    if ($self->{OUTPUTTYPE} eq  "raw"){
    	foreach my $resultline (@result){
    		if ($resultline =~
    		  #SEQNO STIME SSYNC SERR RTIME RSYNC RERR TTL\n
                /(\d+)\s*(\d+)\s*(\d+)\s(.+)\s(\d+)\s(\d+)\s(.+)\s(\d+)/){
                my %data_hash;
                $data_hash{"sequenceNumber"} = $1;
                if ( 0 != $5){  #this checks if receive time is 0 => packet loss ..etc
                    $data_hash{"sendTime"} = $2;
                    $data_hash{"sendSynchronized"} = $3;
                    $data_hash{"sendTimeError"} = $4;
                    $data_hash{"receiveTime"} = $5;
                    $data_hash{"receiveSynchronized"} = $6;
                    $data_hash{"receiveTimeError"} = $7;
                    $data_hash{"packetTTL"} = $8;
                    $data_hash{delay} = owpdelay($data_hash{"sendTime"}, $data_hash{"receiveTime"} );
                }
                push @datalines, \%data_hash;
            } #End foreach
            #We not storing raw only summary
            my $owd_file = $self->get_owd_file();
            my @summaries = split(/\n/, $owd_file);
            my %summary = %{$self->parse_owamp_summary_output(  \@summaries)};
            my @esmonddata;
            push @esmonddata, \%summary;
            $self->{ESMOND}{STORE}{$id} = \@esmonddata;
    	}#End if 
    }elsif ($self->{OUTPUTTYPE} eq  "machine_readable"){
    	my %data_hash = ();
        my %summary = %{$self->parse_owamp_summary_output(  \@result)};
        push @datalines, \%summary;
   }#End if
    elsif ($self->{OUTPUTTYPE} eq  "summary"){
	my $count = 0;
	while( $count < $self->{intermediates} ){
        my %data_hash;
	$count += 1;
    	#foreach my $resultline (@result){  	     
	while(@result){
	    my $resultline = shift(@result);
            next if $resultline =~ /Approximately/;
            next if $resultline =~ /owping: FILE=/;
            next if $resultline =~ s/^\s+//;
            #--- owping statistics from [131.188.81.234]:38399 to [198.124.252.101]:9169 ---            if ($resultline =~
            if ($resultline =~
                /---\s+owping\s+statistics\s+from\s+\[(\S+)\]:(\S+)\s+to\s+\[(\S+)\]:(\S+)/){
                $data_hash{"sender"} = $1;
                $data_hash{"receiver"} = $3; 
            }elsif ($resultline =~
                #10 sent, 0 lost (0.000%), 0 duplicates
                /(\d+)\s+sent,\s+(\d+)\s+lost\s+\((\S+)\),\s+(\d+)\s+duplicates/){
                $data_hash{"sent"} = $1;
                $data_hash{"loss"} = $2;
		my $lostPercentage = substr($3, 0, 1); #delete the percent symbol
                $data_hash{"lost_percent"} = $lostPercentage / 100; #Percent as float
                $data_hash{"duplicates"} = $4;
                #push @datalines, \%data_hash;
	    }elsif ($resultline =~
	    #first:  2012-10-17T11:45:00.601
	    /first:\s+(\d+-\d+-\d+T\d+:\d+:\d+.\d+)/){
		my $starttime = $self->parseOWAMPTime($1);
		$self->{LOGGER}->debug("Starttime: $starttime");
		$data_hash{"startTime"} = $starttime;
	    }elsif ($resultline =~
            #last:   2012-11-29T15:13:11.386
            /last:\s+(\d+-\d+-\d+T\d+:\d+:\d+.\d+)/){
	    my $endTime = $self->parseOWAMPTime($1); 
	    $data_hash{"endTime"} = $endTime;
            } elsif ($resultline =~
                #one-way delay min/median/max = 0.202/0.4/0.582 ms, (err=0.628 ms)
                #/one-way delay min\/median\/max = (\S+\/\S+\/\S+)\s+(\w+),\s+\(err=(.+)\s+(\w+)/){
		/one-way delay min\/median\/max = (\S+\/\S+\/\S+)\s+(\w+),\s+\((.+)\)/){
                my $delay = $1;
                my ($min,$med,$max) = split ("/", $delay);
                $data_hash{"timeType"} = $2;
		if ( $3 =~
		# unsynchronized
		/unsync/ ){
                	$data_hash{"maxError"} = "NaN";
		}elsif (  $3 =~
		#err=0.628 ms
		/err=(.+)\s+(\w+)/){
			$data_hash{"maxError"} = $1;
		}
		#Sometime occur for delay nan adjust it to schema NaN
                $min = "NaN" if $min =~ m/nan/;
                $med = "NaN" if $med =~ m/nan/;
                $max = "NaN" if $max =~ m/nan/;
                $data_hash{"min_delay"} = $min;
                $data_hash{"med_delay"} = $med;
                $data_hash{"max_delay"} = $max;
                #$data_hash{"error_units"} = $4;
                #push @datalines, \%data_hash;
            }elsif ($resultline =~
            #one-way jitter = 0.1 ms (P95-P50)
            /one-way jitter\s+=\s+([0-9.]+)\s+(\w+)\s\(P95-P50\)/){
		my $jitter = $1;
		$jitter = "NaN" if $jitter =~ m/nan/;
                $data_hash{"jitter"} = $jitter;
                #$data_hash{"jitter_units"} = $2;            
	    }elsif ($resultline =~
            #Hops = 12 (consistently)
            /Hops =\s+(\d+)\s+\(consistently\)/){
                $data_hash{"hops"} = $1;
		#Hops is the last line which we use as the end of a summary
		last;
	    }elsif ($resultline =~
	    #TTL not reported
	    /TTL not reported/){
	    $data_hash{"hops"} = 0; #No hops
		 last;
	    }else { next; }
    	}#End foreach
	# Add hash to data container after break from foreach
	push @datalines, \%data_hash; # if (scalar keys %data_hash > 0)
	} #End while ($count <
    }#elsif ($self->{OUTPUTTYPE} eq  "summary"
    #$self->{LOGGER}->info(Dumper(@datalines));
    #$self->{LOGGER}->info( "packets failed: $recTimeiszero ");
    if($#datalines < 0){
        $datalines[0]="OWAMP Error:";
        #check if all packages not received on destination
        my %params =  %{$self->{PARAMS}};
        if ( $recTimeiszero == $params{count} ){
             push @datalines, "Destination endpoint maybe blocked by firewall. No receive time available.";
        }else{
            #no data -> something wrong, write result as error description:
            push @datalines, @result;
        }
        
        my $errorstring = "@datalines";
        $$ds->{ERROROCCUR} = 1;
        $self->{LOGGER}->error($errorstring);
        push @datalines,"error.mp.owamp";    
    } #End if ($#datalines < 0    
    
    return @datalines;
}

=head2 selftest()
Define here the steps for the selftest
=cut
sub selftest{
	my ($self, $ds, $id) = @_;
	$self->{LOGGER} = get_logger(__PACKAGE__);
	my $params = $$ds->{SERVICE}->{DATA};
	my @datalines;
	
	foreach my $id (keys %{$params}){
		my %data_hash;
		
		$data_hash{'owping_command_test'} = [$self->checkTool("owping")];
		$data_hash{"owampd_running_test"} = [$self->checkToolisrunning("owampd")];
		$data_hash{"ntpd_running_test"} = [$self->checkToolisrunning("ntpd")];
	
		push @datalines, \%data_hash;
		$$ds->{SERVICE}->{DATA}->{$id}->{MRESULT} = \@datalines
	}#End foreach
	return;
}

=head2 parseOWAMPTime(owamptime)
The owping returns a time stamp of format: year-month-dayThours:minutes:seconds.millisecond
Use this method to get a time stamp like Wed Aug 25 14:20:09.2638497491 UTC 2010
=cut
sub parseOWAMPTime{

	my ($self,$starttime) = @_;
	my ($date,$time) = split ("T", $starttime);
	my ($year,$month,$day) = split ("-", $date);
	my ($hour,$min,$asec) = split (":", $time);
	my ($sec,$msec) = split ('\.', $asec);

	my $dt = DateTime->new(
		year	=> $year,
		month	=> $month,
		day	=> $day,
		hour	=> $hour,
		minute	=> $min,
		second	=> $sec,
		nanosecond => $msec * 1000
		#time_zone => strftime("%Z", localtime())

	);


	# We need the UTC Time
	my $isoTS = $dt->day_abbr ." ". $dt->month_abbr . " ". $dt->day ." ". $dt->hms ."." . $msec ." UTC " . $dt->year;
	return $isoTS;

}

sub set_metadata_service{
    my $self = shift;
    if ($self->set_metadata_owamp_mp($self->{ESMOND})){
        $self->store_measuremt_data_owamp_mp();
    }else{
    }
}


sub owpdelay {
    my ($start, $end) = @_;

    return ($end - $start)/$scale;
}

sub parse_owamp_summary_output {
    my $self = shift;
    my $summary_output = shift;
    my $retval;

    eval {
        my $conf = Config::General->new( -String => $summary_output);
        my %conf_hash = $conf->getall;
        $retval = \%conf_hash;
    };
    if ($@) {
        $self->{LOGGER}->error("Problem reading summary file: ".$summary_output.": ".$@);
    }

    return $retval;
}

sub get_owd_filename{
    my $self = shift;
    my $owd_file;
    $owd_file = "/tmp/oppd-" . time . ".owd";
    $self->{OWD_FILE} = $owd_file;
}

sub get_owd_file{
    my $self = shift;
    my $owstats = $self->{MODPARAM}->{owstats};
    
    if ($self->{OUTPUTTYPE} eq "raw"){
        $owstats = $owstats . " -M";
    }
 
    my $result = `$owstats $self->{OWD_FILE}`;
    return $result;
}
1;
