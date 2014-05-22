package NMWG::Message;
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
# - Replace more getElementsByTagNameNS and similar using find ?

use strict;
use warnings;

#DEBUG
use Data::Dumper;
#/DEBUG

use Carp;
use XML::LibXML;


my $ns_nmwg = "http://ggf.org/ns/nmwg/base/2.0/";
my $ns_perfsonar = "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/";
my $ns_result = "http://ggf.org/ns/nmwg/result/2.0/";
my $ns_hades = "http://ggf.org/ns/nmwg/tools/hades/2.0/";


sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  #my $source = (@_);
  my $source = shift;
  if ( UNIVERSAL::isa($source,"XML::LibXML::Node") ) {
    $self->{dom} = XML::LibXML->createDocument();
    $self->{dom}->importNode($source);
    $self->{dom}->setDocumentElement($source);
    $self->{ns_nmwg} = $self->{dom}->documentElement->lookupNamespacePrefix($ns_nmwg);
  } elsif ($source) {
    $self->parse_xml($source);
  }
  return $self;
}

# Parse XML code of a NMWG message. Also does some beautifications, like
# making <nmwg:message> the root element of the document. Very helpful for
# ignoring any SOAP header that might be there...
sub parse_xml {
  my $self = shift;
  my $file = shift;
  croak "No XML source to parse!" unless $file;
  my $xml_version = XML::LibXML->VERSION;
  my $dom;
  #eval{ 
  if ( $xml_version < 1.7){
      my $parser = XML::LibXML->new();
      $dom = $parser->parse_file($file);
  }else{
      $dom = XML::LibXML->load_xml(location => $file);
  }

#  };
  if ($@){
    #TODO The following should be sent as NMWG error, not SOAP error
    #return ("Error parsing message: $@", "no_id");
    croak "Error parsing message: $@";
  }
  #TODO The following "trick" only works if $dom contains a REAL NWMG message!
  #     We should at least(!) also check for SOAP errors
  my $nmwg_node = ($dom->getElementsByTagNameNS($ns_nmwg,"message"))[0];
  if(!$nmwg_node){
    #TODO The following should be sent as NMWG error, not SOAP error
    #     This is only relevant the server at all........
    #return ("Error parsing message: message contains no NMWG message tag", "no_id");
    croak "Error parsing message: message contains no NMWG message tag";
  }
  $dom->setDocumentElement($nmwg_node);
  $self->{dom} = $dom;
  $self->{ns_nmwg} = $dom->documentElement->lookupNamespacePrefix($ns_nmwg);
}

sub parse_xml_from_file {
  my $self = shift;
  my $file = shift;
  return $self->parse_xml($file);
}

sub dump {
  my $self = shift;
  my $timestamp = time;
  my $file = "msgdump-$timestamp.xml";
  open (FH, ">", "$file");
  print FH Dumper($self->{dom});
  close FH;
}

sub clone {
  my $self = shift;
  my $new_msg = {
    %$self,
    dom => $self->{dom}->cloneNode(1),
  };
  return bless $new_msg, "NMWG::Message";
}

sub as_string {
  my $self = shift;
  return $self->as_dom->toString(@_);
    #TODO Just passing arguments is ugly and breaks separation NWMG<->LibXML
}

sub as_dom {
  my $self = shift;
  return $self->{dom};
}

sub get_message_type {
  my $self = shift;
  my $node = $self->{dom}->documentElement();
  return $node->getAttribute("type");
}


sub set_message_type {
  my $self = shift;
  my $type = shift;
  my $node = $self->{dom}->documentElement();
  return $node->setAttribute("type", $type);
}

sub add_element {
  my $self = shift;
  my ($parent, $node_name, $e_text) = @_;
  my $e_node;
  $e_node = $parent->addNewChild($ns_nmwg, $node_name);
  $e_node->appendText($e_text);
  return $e_node;
}

sub add_element_NS {
  my $self = shift;
  my ($parent, $node_name, $e_text, $namespace) = @_;
  my $e_node;
  $e_node = $parent->addNewChild($namespace, $node_name);
  $e_node->appendText($e_text);
  return $e_node;
}

sub add_attribute {
  my $self = shift;
  my %params = @_;
  my $ns = $ns_nmwg;
  my $prefix;
  if (defined($params{"namespace"})){
    $ns = $params{"namespace"};
  }
  if (defined($params{"prefix"})){
    $prefix = $params{"prefix"};
  }
  my $name = $params{"parent"}->localname;
  my $a_node = $params{"parent"}->addNewChild($ns, $params{"nodename"});
  if ($prefix){
    $a_node->setNamespace($ns, $prefix, 1);
  }
  while ( my ($name, $value) = each %params){
    next if $name eq "parent";
    next if $name eq "nodename";
    next if $name eq "namespace";
    next if $name eq "prefix";
    $a_node->setAttribute($name, $value);
  }
  return $a_node;
}

sub add_node {
  my $self = shift;
  my $node = shift;
  my $parentnode = shift;
  my $childnode  = $parentnode->addChild( $node );
  # TODO if ($childnode != $node){ #error }
}

sub remove_node {
  my $self = shift;
  my $node = shift;
  my $parentnode = $node->parentNode;
  my $childnode = $parentnode->removeChild($node);
  # TODO if ($childnode != $node){ #error! }
}

sub remove_node_by_ID {
  my $self = shift;
  my $ID = shift;
  my $node = $self->{dom}->find(
    "/$self->{ns_nmwg}:message/$self->{ns_nmwg}:*[\@id='$ID']")->[0];
  if ($node){
    my $parentnode = $node->parentNode;
    my $childnode = $parentnode->removeChild($node);
  } # TODO else { error!}
}

#set list of new parameter blocks
sub set_parameter_list {
  my $self = shift;
  my @list = @_;


  my $root = $self->{dom}->documentElement();

  foreach my $par (@list){
    my $metaid = $$par{"metadataIdRef"};
    #add child to root node
    my $metanode = $self->add_attribute(parent => $root, nodename => "metadata", id => $metaid);
    #add subject node (for completeness)
    #$self->add_attribute(parent => $metanode, nodename => "subject", id => "subject-$metaid", namespace => $ns_perfsonar);
    #add new parameters node
    my $paramnode = $self->add_attribute(parent => $metanode, nodename => "parameters", id => "param1");
    foreach my $key (keys %{$par}){
      next if $key eq "metadataIdRef";
      $self->add_attribute(parent => $paramnode, nodename => "parameter",
                           name => $key, value => $$par{$key});
    }
  }
}


#set parameters for response (which are not set already from request)
sub set_parameter_hash {
  my $self = shift;
  my %parameter = @_;
  my @params;
  my $newnode = 1;
  my $paramnode;
  my @paramnodes;
  my $metanode;
  my $metaid = $parameter{"metadataIdRef"};

  # find metadata node:
  $metanode = $self->{dom}->find(
    "/$self->{ns_nmwg}:message/$self->{ns_nmwg}:metadata[\@id='$metaid']"
  )->[0]; # id should be unique -> use first found element, ignore rest
  if (defined $metanode && $metanode->isa("XML::LibXML::Element")) {
    #@paramnodes = $metanode->getElementsByLocalName("parameters");
    $paramnode = ($metanode->getElementsByLocalName("parameters"))[0]; #TODO
    #$paramnode =
    #  ($metanode->getElementsByTagNameNS("$ns_nmwg", "parameters"))[0];
  }

  #if there was no matching node, create new node
  if(!($metanode)){
    #add child to root node
    my $root = $self->{dom}->documentElement();
    $metanode = $self->add_attribute(parent => $root, nodename => "metadata", id => $metaid);
    #add subject node (for completeness)
    $self->add_attribute(parent => $metanode, nodename => "subject", id => "subject-$metaid");

  }

  #add new parameters node, if none was provided in request
  if(!($paramnode)){
    $paramnode = $self->add_attribute(parent => $metanode, nodename => "parameters", id => "param1");
  
  }
  if ($paramnode->hasChildNodes){
    @params = $paramnode->getChildNodes();
  }
  #startTime, endTime, src, dst, eventType are already set from the request!
  foreach my $key (keys %parameter){
    next if ($key eq "startTime" || $key eq "endTime" ||
             $key eq "src" || $key eq "dst" || $key eq "eventType" ||
             $key eq "lastmeta" || $key eq "metadataIdRef");
    #set all other values in nmwg:parameters:
    #check, if parameter is already set
    $newnode = 1;
    if (@params){
      foreach my $param (@params){
        next unless ($param->nodeName =~ /parameter/);
        if ($param->getAttribute("name") eq $key){ #already set
          $newnode = 0;
        }
      }
    }
    if ($newnode){ #make new parameter entry
      $self->add_attribute(parent => $paramnode, nodename => "parameter", 
                           name => $key, value => $parameter{$key});
    }
  }
}

#fill in data lines for response
sub set_data {
  my $self = shift;
  my $dataid = shift;
  my @lines = @_;

  # find data node:
  my $datanode = $self->{"dataIDs"}{$dataid}{"node"};
  if (defined $datanode && $datanode->isa("XML::LibXML::Element")) {
    foreach my $line (@lines){
      my $newdataline = $self->add_attribute(parent => $datanode, nodename => "datum",
                        %{$line});
      if(!($newdataline)){
        return ("Error writing data line", "$dataid");
      }
    }
  }
}

#fill in data lines for response with namespace URI
sub set_data_ns {
  my $self = shift;
  my $dataid = shift;
  my $ns = shift;
  my @lines = @_;

  # find data node:
  my $datanode = $self->{"dataIDs"}{$dataid}{"node"};
  if (defined $datanode && $datanode->isa("XML::LibXML::Element")) {
    foreach my $line (@lines){
      my $newdataline = $self->add_attribute(parent => $datanode, nodename => "datum",
         namespace => $ns, %{$line});
      if(!($newdataline)){
        return ("Error writing data line", "$dataid");
      }
    }
  }
}


#fill in "freeform" string data
sub set_data_string {
  my $self = shift;
  my $dataid = shift;
  my $string = shift;

  # find data node:
  my $datanode = $self->{"dataIDs"}{$dataid}{"node"};
  if (defined $datanode && $datanode->isa("XML::LibXML::Element")) {
    $self->add_element_NS($datanode, "datum", $string, $ns_nmwg);
  }
} 

#parse data AND metadata blocks
sub parse_all {
  my $self = shift;
  my $root = $self->{dom}->documentElement();
  my @nodes = $root->getChildNodes();
  my %meta;
  unless (@nodes){
    return ("Error parsing message: No metadata tag found", "no_id");
  }
  foreach my $node (@nodes){
    if ($node->nodeName =~ /:metadata/){
      my $metaid;
      if (!($metaid= $node->getAttribute("id"))){ #no metadata id given!
        #error
        return ("No metadata ID given", "no_id");
      }
      #check if metadataID is already existent (has to be unique!)
      if ($self->{"metadataIDs"}{$metaid}){
        return ("Multiple assignement of metadata id: $metaid", "$metaid");
      }

      #TODO
      #metaref in metadata element also! What to do if defined in metadata AND subject??
      #if (my $metaref= $node->getAttribute("metadataIdRef")){ 
      #  $self->{"metadataIDs"}{$metaid}{"metaref"}=$metaref;
      #}
      my $error = $self->parse_metadata($node, $metaid);
      if ($error){
        return ($error, $metaid);
      }
    } elsif ($node->nodeName =~ /:data/){
      my $dataid;
      if (!($dataid= $node->getAttribute("id"))){ #no data id given!
        #error
        return ("No data ID given", "no_id");
      }
      my $metaref;
      if (!($metaref= $node->getAttribute("metadataIdRef"))){ #no reference to metadata given!
        #error
        return ("No reference to metadata block given", "$dataid");
      }
      $self->{"dataIDs"}{$dataid}{"node"} = $node;
      $self->{"dataIDs"}{$dataid}{"metaref"} = $metaref;
    }
  }
  #Check for metadatarefs in metadata tag with different subject namespaces TODO
    
} 


sub parse_metadata {
  my $self = shift;
  my ($metanode, $metaid) = @_;

  if (!($metanode->hasChildNodes())){ #empty metadata
    #error
    return ("Empty metadata");
  }
  #$self->{"metadataIDs"}{$metaid}{"node"} = $metanode;
  my $error = undef;

  # a metadatablock can contain 4 different kinds of subelements: a parameters block,
  # a subject block, a key block, and an eventType element.

  foreach my $child ($metanode->getChildNodes()){
    if ($child->nodeName =~ /subject/) {
      return $error if ($error = $self->parse_subject($metaid, $child));
    }

    if ($child->nodeName =~ /parameters/) {
      return $error if ($error = $self->parse_parameters($metaid, $child));
      
    }
    if ($child->nodeName =~ /key/){
      return $error if ($error = $self->parse_key($metaid, $child));
    }
    
    $self->{"metadataIDs"}{$metaid}{"eventType"} =
      $child->textContent if ($child->nodeName =~ /eventType/);
    $self->{"metadataIDs"}{$metaid}{"eventType"} =~ s/^\s*(\S*)\s*/$1/
      if $self->{"metadataIDs"}{$metaid}{"eventType"}; #Throw away any whitespace and newlines
  }  
  if(!$self->{"metadataIDs"}{$metaid}{"eventType"}){ #TODO eventtype could be in other metadatablock! chaining....
                                                     #error message only, if there is no eventtype per _chain_.
    return ("Error parsing message: No event type given");
  }
  if($self->{"metadataIDs"}{$metaid}{"eventType"} eq "success.as.authn"){ #metadata from successful authentication
    delete $self->{"metadataIDs"}{$metaid}; #throw away
    return;
  }
  #return ("Error parsing message: No subject in metadata", $metaid) if(!@sub_nodes && !@key_nodes); #TODO
  
  if (my $metaref= $metanode->getAttribute("metadataIdRef")){
  	#i2 and GEANT response is different for LS
  	if ( $metanode->getAttribute("metadataIdRef") eq "serviceLookupInfo"){
  		#TODO check this for LS
  	}elsif($self->{"metadataIDs"}{$metaid}{"subject_ns_uri"} eq $self->{"metadataIDs"}{$metaref}{"subject_ns_uri"}){
      $self->{"metadataIDs"}{$metaid}{"metaref"}=$metaref;
    }else {
      return ("Metadata $metaid and $metaref have subjects with different namespaces.");
    }
  }


  #TODO
  #print Dumper ($self->{"metadataIDs"});
  return 0;  
}


sub parse_subject {
  my $self = shift;
  my $metaid = shift;
  my $sub = shift;

  if(!($self->{"metadataIDs"}{$metaid}{"subject"} = $sub->getAttribute("id"))){
    return ("Error parsing message: No subject id given");
  }
  #find out namespace for subject:
  $self->{"metadataIDs"}{$metaid}{"subject_ns_prefix"} = $sub->prefix;
  $self->{"metadataIDs"}{$metaid}{"subject_ns_uri"} = $sub->namespaceURI();
  
  my $ref;
  if ($ref = $sub->getAttribute("metadataIdRef")){
    $self->{"metadataIDs"}{$metaid}{"metaref"} = $ref;
  }
  if ($ref = $sub->getAttribute("dataIdRef")){
    $self->{"metadataIDs"}{$metaid}{"dataref"} = $ref;
  }
  foreach my $sub_kid ($sub->getChildNodes()){
    if (($sub_kid->nodeName =~/endPoint/) #get endpoint(pair), get interface etc still needed.
      && $sub_kid->hasChildNodes()){
      foreach my $end_point ($sub_kid->getChildNodes()){
        if ($end_point->hasAttributes()){
          $self->{"metadataIDs"}{$metaid}{$end_point->localname}{"type"} =
              $end_point->getAttribute("type");
          $self->{"metadataIDs"}{$metaid}{$end_point->localname}{"value"} =
              $end_point->getAttribute("value");

        }
      }
    }
  }
  return 0;
}  

sub parse_parameters {
  my $self = shift;
  my $metaid = shift;
  my $par = shift;

  my $parId;
  if(!($self->{"metadataIDs"}{$metaid}{"parameter_ID"} = $par->getAttribute("id"))){
    return ("Error parsing message: No parameters id given");
  }
  #find out namespace for parameters:
  $self->{"metadataIDs"}{$metaid}{"param_ns_prefix"} = $par->prefix;
  $self->{"metadataIDs"}{$metaid}{"param_ns_uri"} = $par->namespaceURI();

  if ($par->hasChildNodes()){
    foreach my $p ($par->getChildNodes){
      next if $p->nodeName =~ /\#text/ || $p->nodeName =~ /\#comment/;
      if (!($p->nodeName =~ /:parameter$/)){
        my $err_msg = "Error parsing message: wrong element found in parameters: "
                      . $p->nodeName; 
        return ("$err_msg");
      }
      if($p->hasAttributes()){
        my $value;
        if(!defined($value = $p->getAttribute("value"))){       
          if (!($value = $p->textContent)){
            return ("Error parsing message: malformed parameter, "
                  . "no textContent or name/value pair found!");
          } 
        }
        $self->{"metadataIDs"}{$metaid}{$p->getAttribute("name")} = $value;
      }
    }
  }
  return 0;
}

sub parse_key {
  my $self = shift;
  my $metaid = shift;
  my $key = shift;

  if (!($key->hasChildNodes())){ #empty key!
    #error
    return ("Error parsing message: Empty key");
  }
  foreach my $sub_key ($key->getChildNodes){
    next unless ($sub_key->nodeName =~ /parameters/);
    foreach my $k ($sub_key->getChildNodes){
      next unless ($k->nodeName =~ /parameter/);
      if($k->hasAttributes()){
        my $value;
        if(!($value = $k->getAttribute("value"))){
          $value = $k->textContent;
        }
        $self->{"metadataIDs"}{$metaid}{"key"}{$k->getAttribute("name")} = $value;
      }
    }
  }
  return 0;
}

#add parameters from all referenced metadatablocks to corresponding datablock
sub concatenate_params {
  my $self = shift;

  foreach my $dataid (keys %{$self->{"dataIDs"}}){
    my $meta = $self->{"dataIDs"}{$dataid}{"metaref"};
    my $oldmeta;
    my $et;
    do {
      #check if metadataIDref points to an existing metadata element!
      if (!defined ($self->{"metadataIDs"}{$meta})){
        return ("Reference to unknown metadata element (metadataIdRef): $meta", "$dataid");
      }
      if ($self->{"metadataIDs"}{$meta} eq "message") { #authn
        delete $self->{"dataIDs"}{$dataid}; #throw away
        next;
      }

      $et = $self->{"metadataIDs"}{$meta}{"eventType"}; #TODO eventtype is not necessarily in each metadata block!
      $self->{"dataIDs"}{$dataid}{$et}{"metaID"} = $meta;
      foreach my $elem (keys %{$self->{"metadataIDs"}{$meta}}){
        next if ($elem eq "subject" || $elem eq "metaref" || $elem eq "eventType" 
              || $elem eq "type");
              #|| $elem eq "type" || $elem eq "ns_uri" || $elem eq "ns_prefix");
        #if ($elem eq "eventType"){
        #   $self->{"dataIDs"}{$dataid}{"eventTypes"}{$meta} = $self->{"metadataIDs"}{$meta}{$elem};
        #} else {
          $self->{"dataIDs"}{$dataid}{$et}{$elem} = $self->{"metadataIDs"}{$meta}{$elem};
        #}
      }
      $oldmeta = $meta;
    }
    while defined ($meta = $self->{"metadataIDs"}{$oldmeta}{"metaref"});
  }
}

#parse data section
sub parse_data {
  my $self = shift;
  my @nodes = $self->{dom}->getElementsByTagNameNS("$ns_nmwg", "data");
  unless (@nodes){
    return ("Error parsing message: No data tag found", "no_id");
  }
  foreach my $datanode (@nodes){
    my $dataid;
    if (!($dataid= $datanode->getAttribute("id"))){ #no datadata id given!
      return ("No data ID given", "no_id");
    }
    my $metaref = $datanode->getAttribute("metadataIdRef");
    if (!($datanode->hasChildNodes())){ #empty data
       return ("Empty data", $dataid);
    }
    my @datum_lines;
    foreach my $datum ($datanode->getChildNodes()){ 
      next unless ($datum->nodeName =~ /datum/ && $datum->hasAttributes());
      my  %line;
      my @attributelist = $datum->attributes;
      foreach my $a (@attributelist){
        $line{$a->name} = $a->value;
      }
      push @datum_lines, \%line;
    }
    $self->{$dataid}->{"metaref"} = $metaref;
    $self->{$dataid}->{"data"} = \@datum_lines;
    #print Dumper ($self->{$dataid});
  }
}


#return result codes: e.g. error.ma.whatever/success.mp.great
sub return_result_code {
  my $self = shift;
  my $result_code = shift;
  my $description = shift;
  my $metaid = shift;
  my $id = shift;
  
  if (!$id){
    $id = "return_$metaid";
  }
  
  #create metadata entry with result_code
  my $messagenode = $self->{dom}->documentElement();
  #$messagenode->setAttribute("xmlns:result", $ns_result);
  $messagenode->setNamespace($ns_result, "nmwgr", 0);
  my $metanode = $self->add_attribute(parent => $messagenode, nodename => "metadata", id => $id);
  my $string = $self->{dom}->toString;
  #my $subjectnode = $self->add_attribute(parent => $messagenode, nodename => "subject",
  #my $subjectnode = $self->add_attribute(parent => $metanode, nodename => "subject", 
  #                                       id => "subjreturn", metadataIdRef => $metaid, "namespace" => $ns_result);
  my $eventnode = $self->add_element($metanode, "eventType", $result_code);

  #create data entry with description
  my $datanode = $self->add_attribute(parent => $messagenode, nodename => "data", 
                                      id => "data_$id", metadataIdRef => $id);
  my $datumnode = $self->add_element_NS($datanode, "datum", $description, $ns_result);
}


sub create_metadatablock {
  my $self = shift;
  my %par =  @_;
  
  my $parent;
  my $metaid;

  if ($par{"parent"}){
    $parent = $par{"parent"};
  } else {
    $parent = $self->{dom}->documentElement();
  }

  if ($par{"metadata_id"}){
    $metaid = $par{"metadata_id"};
  } else {
    $metaid = rand;
  }


  my $metanode = $self->add_attribute (parent => $parent, nodename => "metadata",
                                       id => $metaid);

  if ($par{"subject"}){
    #create subject
    my $subjectnode = $self->add_attribute (parent => $metanode, nodename => "subject",
                                            id => "subject-$metaid");
    
    my $subref = $par{"subject"};
                        
  }

  if ($par{"substring"}){
    $metanode->appendWellBalancedChunk($par{substring});
  }


  if ($par{"eventtypes"}){
    #create eventtypes
    foreach my $et (@{$par{"eventtypes"}}){
      $self->add_element($metanode, "eventType", $et);   
    }
  }

  if ($par{"parameters"}){
    #create parameters
    my $paramnode = $self->add_attribute (parent => $metanode, nodename => "parameters",
                                          id => "params-$metaid");
    foreach my $key (keys %{$par{"parameters"}}){
      $self->add_attribute (parent => $paramnode, nodename => "parameter",
                            name => $key, value => $par{parameters}{$key});
    }
  }


}

sub create_subject_recursive {
  my $self = shift;
  my $ref = shift;
  my $parent = shift;

  my $ns = $ref->{"namespace"};
  my $prefix = $ref->{"prefix"};  


  foreach my $k (keys %{$ref}){
    next if $k eq "namespace";
    next if $k eq "prefix";
    my $val = $ref->{$k};
    if (ref $val eq 'HASH'){
      my $p = $self->add_attribute (nodename => $k, parent => $parent,
                                    namespace => $ns, prefix => $prefix);
      $self->create_subject_recursive (\%{$val}, $p);
    } else {
      if ($k eq "element"){
        $parent->appendText($val);
      } else {
        $parent->setAttribute ($k, $val);
      }
    }
  }
}


1;
