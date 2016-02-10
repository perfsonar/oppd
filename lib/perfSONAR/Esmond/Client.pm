package perfSONAR::Esmond::Client;
  
=head1 NAME

perfSONAR::Esmond::Client - Client for storing data in Esmond storage.

=head1 DESCRIPTION
This class includes all methods for storing measurement data in a Esmond storage.
=cut

use strict;
use warnings;

#DEBUG
use Data::Dumper;
##DEBUG


use Log::Log4perl qw(get_logger);
use JSON;
use Scalar::Util qw(reftype);
use FindBin;
use lib "$FindBin::RealBin/../../toolkit/lib/";
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Metadata;

sub new {
    my $class = @_;
    my $self = {};
    bless $self, $class;
    $self->{LOGGER} = get_logger(__PACKAGE__);
    return $self;
}

sub connect_storage{
    my ($self, $params_ref) = @_;
    my %params = %{$params_ref};
    my $storage_url = "";
    if (defined $params{url}){ 
	$storage_url = $params{url};
	$self->{LOGGER}->info("Connecting to Esmond storage: $storage_url");
        $self->{METADATA} = new perfSONAR_PS::Client::Esmond::Metadata(
            url => $storage_url,
            filters =>  $self->get_auth_filter(\%params)
        );
    } else{
        $self->{LOGGER}->error("No storage url defined. Cannot store measurement data.");
        return -1;
    }
}

=head2 get_auth_filter(%parameters)
Create a authentication filter for Esmond.
=cut
sub get_auth_filter{
    my ($self, $params_ref) = @_;
    my %params = %{$params_ref};
    return new perfSONAR_PS::Client::Esmond::ApiFilters(
    			'auth_username' => $params{username},
			    'auth_apikey' => $params{apikey},
			    'ca_certificate_file' => $params{ca_file}
			    );
}

sub set_subject_type{
    my ($self, $subject_type) = @_;
    $self->{METADATA}->subject_type($subject_type);
}

sub set_source{
    my ($self, $source) = @_;
    $self->{METADATA}->source($source);
}

sub set_destination{
    my ($self, $destination) = @_;
    $self->{METADATA}->destination($destination);
}

sub set_input_source{
    my ($self, $input_source) = @_;
    $self->{METADATA}->input_source($input_source);
}

sub set_input_destination{
    my ($self, $input_destination) = @_;
    $self->{METADATA}->input_destination($input_destination);
}

sub set_tool_name{
    my ($self, $tool_name) = @_;
    $self->{METADATA}->tool_name($tool_name);
}

sub set_measurement_agent{
    my ($self, $measurement_agent) = @_;
    $self->{METADATA}->measurement_agent($measurement_agent);
}

sub set_metadata_general{
    my ($self, $params_ref) = @_;
    my %params = %{$params_ref};
    $self->set_subject_type($params{subject_type});
    $self->set_source($params{source});
    $self->set_destination($params{destination});
    $self->set_input_source($params{input_source});
    $self->set_input_destination($params{input_destination});
    $self->set_tool_name($params{tool_name});
    $self->set_measurement_agent($params{measurement_agent});
}

sub set_metadata_bwctl_mp{
    my ($self, $params_ref) = @_;
    my %params = %{$params_ref};
    $self->{METADATA}->set_field('ip-transport-protocol', 'tcp');
    #$self->{METADATA}->set_field('time-interval', $params{interval});
    $self->{METADATA}->set_field('time-duration', $params{duration});
    $self->{METADATA}->add_event_type('throughput');
    $self->{METADATA}->add_summary_type('throughput', 'average', 86400);
    $self->{METADATA}->add_event_type('failures');
    $self->{METADATA}->add_event_type('packet-retransmits');
    $self->{METADATA}->add_event_type('throughput-subintervals');
   $self->{METADATA}->post_metadata();
   if ($self->{METADATA}->error()){
       $self->{LOGGER}->error( "Post metadata error:" . $self->{METADATA}->error());
       return 0;
    }else{
        return 1;
    }
}

sub set_metadata_owamp_mp{
    my ($self, $params_ref) = @_;
    my %params = %{$params_ref};

    $self->{METADATA}->set_field('ip-transport-protocol', $params{ip_transport_protocol});
    #$self->{METADATA}->set_field('ip-packet-size', $params{ip_packet_size});
    $self->{METADATA}->set_field('time-interval', 0); #owpng has no interval
    #$self->{METADATA}->set_field('sample-size', 600);
    $self->{METADATA}->set_field('sample-bucket-width', $params{sample_bucket_width});
    #event  types
    $self->{METADATA}->add_event_type('histogram-owdelay');
    $self->{METADATA}->add_summary_type('histogram-owdelay', 'aggregation', 3600);
    $self->{METADATA}->add_summary_type('histogram-owdelay', 'aggregation', 86400);
    $self->{METADATA}->add_summary_type('histogram-owdelay', 'statistics', 0);
    $self->{METADATA}->add_summary_type('histogram-owdelay', 'statistics', 3600);
    $self->{METADATA}->add_summary_type('histogram-owdelay', 'statistics', 86400);

    $self->{METADATA}->add_event_type('packet-loss-rate');
    $self->{METADATA}->add_summary_type('packet-loss-rate', 'aggregation', 3600);
    $self->{METADATA}->add_summary_type('packet-loss-rate', 'aggregation', 86400);

    $self->{METADATA}->add_event_type('histogram-ttl');
    $self->{METADATA}->add_summary_type('histogram-ttl', 'statistics', 0);

    $self->{METADATA}->add_event_type('packet-count-lost');
    $self->{METADATA}->add_event_type('packet-count-sent');
    $self->{METADATA}->add_event_type('packet-duplicates');
    $self->{METADATA}->add_event_type('time-error-estimates');
    $self->{METADATA}->add_event_type('failures');
    $self->{METADATA}->post_metadata();

    if ($self->{METADATA}->error()){
       $self->{LOGGER}->error( "Post metadata error:" . $self->{METADATA}->error());
       return 0;
    }else{
        return 1;
    }
}



sub store_measuremt_data_bwctl_mp{
    my $self = shift;
    my $ds = $self->{DS};
    my $datalines_ref = $$ds->{SERVICE}->{DATA}->{1}->{MRESULT};
    my $bulk_post = $self->{METADATA}->generate_event_type_bulk_post();
    my $ts;
    my $subintervals = $self->get_throughput_subintervals_json($datalines_ref);

    foreach(@$datalines_ref){
        if ($_->{'lineType'} eq  'summary' && $_->{'nodeType'} eq 'sender'){
            $ts = $_->{'timeValue'};
            $bulk_post->add_data_point('throughput', $ts, $_->{'value'} * 1000  );
            $bulk_post->add_data_point('packet-retransmits', $ts, $_->{'retransmits'} ) if $_{'retransmits'} >=0;
        }
    } 
    $bulk_post->add_data_point('throughput-subintervals', $ts, $subintervals); 
    $bulk_post->post_data();
    if($bulk_post->error()){
        $self->{LOGGER}->error($bulk_post->error());
    }
}

sub store_measuremt_data_owamp_mp{
    my $self = shift;
    my $ds = $self->{DS};
    my $datalines_ref;
    if ($self->{OUTPUTTYPE} eq "machine_readable"){
        $datalines_ref = $$ds->{SERVICE}->{DATA}->{1}->{MRESULT};
    }elsif($self->{OUTPUTTYPE} eq "raw"){
        $datalines_ref = $self->{ESMOND}{STORE}{1};
    }
    my $bulk_post = $self->{METADATA}->generate_event_type_bulk_post();
    my $ts = time;

    foreach(@$datalines_ref){
        #$self->{LOGGER}->info(Dumper($self->get_histogram_owdelay($_)));
        $bulk_post->add_data_point('histogram-owdelay', $ts, $self->get_histogram_owdelay($_));
        #$bulk_post->add_data_point('packet-loss-rate', $ts, {'numerator'=> $_->{loss}, 'denominator'=> $_->{sent}});
        my %ttls = ();
        %ttls = %{ $_->{TTLBUCKETS} } if $_->{TTLBUCKETS};
        $bulk_post->add_data_point('histogram-ttl', $ts, \%ttls);
        $bulk_post->add_data_point('packet-count-lost', $ts, $_->{LOST});
        $bulk_post->add_data_point('packet-count-sent', $ts, $_->{SENT});
        $bulk_post->add_data_point('packet-duplicates', $ts, $_->{DUPS});
        $bulk_post->add_data_point('time-error-estimates', $ts, $_->{MAXERR});
        $bulk_post->post_data();
    
        if($bulk_post->error()){
            $self->{LOGGER}->error($bulk_post->error());    
        }
    }
}

sub get_throughput_subintervals_json{
    my ($self, $datalines_ref) = @_;
    my @data = ();
    #my $subintervals_str = "";

    foreach(@$datalines_ref){
        if ($_->{'lineType'} eq  'data' ){
            my ($start, $duration) = $self->get_start_duration($_->{interval});
            push(@data,  {val => $_->{'value'} * 1000, duration => $duration, start => $start});  
        }
    }
    return \@data;
}

sub get_start_duration{
    my ($self, $interval) =  @_;
    # 'interval' => '6.00-12.00',
    $interval =~  /(\d+\.\d*)-(\d+\.\d*)/;
    my ($start, $end);
    $start = $1;
    $end  = $2;
    return $start, $end - $start;
}

sub get_histogram_owdelay{
    my ($self, $summary) = @_;
    my %delays = ();
    foreach my $bucket (keys %{ $summary->{BUCKETS} }) {
       $delays{$bucket * $summary->{BUCKET_WIDTH} * 1000.0} = $summary->{BUCKETS}->{$bucket};
    }
    return \%delays;
}
1;
