package resources2::matrix;

use strict;
use warnings;
no warnings('once');
use POSIX qw(strftime);

use Conf;
use MGRAST::Metadata;
use MGRAST::Analysis;
use Babel::lib::Babel;
use Data::Dumper;
use parent qw(resources2::resource);

# Override parent constructor
sub new {
    my ($class, @args) = @_;

    # Call the constructor of the parent class
    my $self = $class->SUPER::new(@args);
    
    # Add name / attributes
    $self->{name} = "matrix";
    $self->{org2tax} = {};
    $self->{hierarchy} = { organism => [ ['strain', 'bottom organism taxanomic level'],
				                         ['species', 'organism type level'],
				                         ['genus', 'organism taxanomic level'],
				                         ['family', 'organism taxanomic level'],
				                         ['order', 'organism taxanomic level'],
				                         ['class', 'organism taxanomic level'],
				                         ['phylum', 'organism taxanomic level'],
				                         ['domain', 'top organism taxanomic level'] ],
				           ontology => [ ['function', 'bottom ontology level (function:default)'],
                                         ['level3', 'function type level (function)' ],
                                         ['level2', 'function type level (function)' ],
                          	             ['level1', 'top function type level (function)'] ]
                         };
    $self->{attributes} = { "id"                   => [ 'string', 'unique object identifier' ],
    	                    "format"               => [ 'string', 'format specification name' ],
    	                    "format_url"           => [ 'string', 'url to the format specification' ],
    	                    "type"                 => [ 'string', 'type of the data in the return table (taxon, function or gene)' ],
    	                    "generated_by"         => [ 'string', 'identifier of the data generator' ],
    	                    "date"                 => [ 'date', 'time the output data was generated' ],
    	                    "matrix_type"          => [ 'string', 'type of the data encoding matrix (dense or sparse)' ],
    	                    "matrix_element_type"  => [ 'string', 'data type of the elements in the return matrix' ],
    	                    "matrix_element_value" => [ 'string', 'result_type of the elements in the return matrix' ],
    	                    "shape"                => [ 'list', ['integer', 'list of the dimension sizes of the return matrix'] ],
    	                    "rows"                 => [ 'list', ['object', [{'id'       => ['string', 'unique annotation text'],
    						                                                 'metadata' => ['hash', 'key value pairs describing metadata']}, "rows object"]] ],
    	                    "columns"              => [ 'list', ['object', [{'id'       => ['string', 'unique metagenome identifier'],
    							                                             'metadata' => ['hash', 'key value pairs describing metadata']}, "columns object"]] ],
    	                    "data"                 => [ 'list', ['list', ['float', 'the matrix values']] ]
                          };
    return $self;
}

# resource is called without any parameters
# this method must return a description of the resource
sub info {
    my ($self) = @_;
    my $content = { 'name' => $self->name,
    		        'url' => $self->cgi->url."/".$self->name,
    		        'description' => "A profile in biom format that contains abundance counts",
    		        'type' => 'object',
    		        'documentation' => $Conf::cgi_url.'/Html/api.html#'.$self->name,
    		        'requests' => [ { 'name'        => "info",
    				                  'request'     => $self->cgi->url."/".$self->name,
    				                  'description' => "Returns description of parameters and attributes.",
    				                  'method'      => "GET" ,
    				                  'type'        => "synchronous" ,  
    				                  'attributes'  => "self",
    				                  'parameters'  => { 'options'  => {},
    						                             'required' => {},
    						                             'body'     => {} }
    						        },
    						        { 'name'        => "organism",
    				                  'request'     => $self->cgi->url."/".$self->name."/organism",
    				                  'description' => "Returns a single data object.",
    				                  'method'      => "GET" ,
    				                  'type'        => "synchronous" ,  
    				                  'attributes'  => $self->attributes,
    				                  'parameters'  => { 'options'  => { 'result_type' => [ 'cv', [['abundance', 'number of reads with hits in annotation'],
                      						                                                       ['evalue', 'average e-value exponent of hits in annotation'],
                      						                                                       ['identity', 'average percent identity of hits in annotation'],
                      						                                                       ['length', 'average alignment length of hits in annotation']] ],
    									                                 'source' => [ 'cv', [["M5NR", "comprehensive protein database"],
    									                                                      ["RefSeq", "protein database"],
    												                                          ["SwissProt", "protein database"],
    												                                          ["GenBank", "protein database"],
    												                                          ["IMG", "protein database"],
    												                                          ["SEED", "protein database"],
    												                                          ["TrEMBL", "protein database"],
    												                                          ["PATRIC", "protein database"],
    												                                          ["KEGG", "protein database"],
    												                                          ["M5RNA", "comprehensive RNA database"],
                          												                      ["RDP", "RNA database"],
                          												                      ["Greengenes", "RNA database"],
                          									                                  ["LSU", "RNA database"],
                          								                                      ["SSU", "RNA database"]] ],
    												                     'group_level' => [ 'cv', $self->{hierarchy}{organism} ],
                                                         				 'id' => [ "string", "one or more metagenome or project unique identifier" ] },
    						                             'required' => {},
    						                             'body'     => {} }
    						        },
    						        { 'name'        => "function",
    				                  'request'     => $self->cgi->url."/".$self->name."/function",
    				                  'description' => "Returns a single data object.",
    				                  'method'      => "GET" ,
    				                  'type'        => "synchronous" ,  
    				                  'attributes'  => $self->attributes,
    				                  'parameters'  => { 'options'  => { 'result_type' => [ 'cv', [['abundance', 'number of reads with hits in annotation'],
                        						                                                   ['evalue', 'average e-value exponent of hits in annotation'],
                        						                                                   ['identity', 'average percent identity of hits in annotation'],
                        						                                                   ['length', 'average alignment length of hits in annotation']] ],
    									                                 'source' => [ 'cv', [["Subsystems", "ontology database, type function only"],
    									                                                      ["NOG", "ontology database, type function only"],
    												                                          ["COG", "ontology database, type function only"],
    												                                          ["KO", "ontology database, type function only"]] ],
    												                     'group_level' => [ 'cv', $self->{hierarchy}{ontology} ],
    												                     'id' => [ "string", "one or more metagenome or project unique identifier" ] },
    						                             'required' => {},
    						                             'body'     => {} }
    						        },
    				                { 'name'        => "feature",
    				                  'request'     => $self->cgi->url."/".$self->name."/feature",
    				                  'description' => "Returns a single data object.",
    				                  'method'      => "GET" ,
    				                  'type'        => "synchronous" ,  
    				                  'attributes'  => $self->attributes,
    				                  'parameters'  => { 'options'  => { 'result_type' => [ 'cv', [['abundance', 'number of reads with hits in annotation'],
                        						                                                   ['evalue', 'average e-value exponent of hits in annotation'],
                        						                                                   ['identity', 'average percent identity of hits in annotation'],
                        						                                                   ['length', 'average alignment length of hits in annotation']] ],
    									                                 'source' => [ 'cv', [["RefSeq", "protein database"],
    									                                                      ["SwissProt", "protein database"],
                               											                      ["GenBank", "protein database"],
                               										                          ["IMG", "protein database"],
                               											                      ["SEED", "protein database"],
                               								                                  ["TrEMBL", "protein database"],
                               												                  ["PATRIC", "protein database"],
                               									                              ["KEGG", "protein database"],
                               									                              ["RDP", "RNA database"],
                                                     								          ["Greengenes", "RNA database"],
                                                     								          ["LSU", "RNA database"],
                                                     								          ["SSU", "RNA database"]] ],
                               									         'id' => [ "string", "one or more metagenome or project unique identifier" ] },
    						                             'required' => {},
    						                             'body'     => {} } }
    				              ] };
    $self->return_data($content);
}

# Override parent request function
sub request {
    my ($self) = @_;
    # determine sub-module to use
    if (scalar(@{$self->rest}) == 0) {
        $self->info();
    } elsif (($self->rest->[0] eq 'organism') || ($self->rest->[0] eq 'function') || ($self->rest->[0] eq 'feature')) {
        $self->instance($self->rest->[0]);
    } else {
        $self->info();
    }
}

# the resource is called with a parameter
sub instance {
    my ($self, $type) = @_;
    
    # get id set
    unless ($self->cgi->param('id')) {
        $self->return_data( {"ERROR" => "no ids submitted, aleast one 'id' is required"}, 400 );
    }
    my @ids   = $self->cgi->param('id');
    my $mgids = {};
    my $seen  = {};
        
    # get database
    my $master = $self->connect_to_datasource();

    # get user viewable
    my %p_rights = $self->user ? map {$_, 1} @{$self->user->has_right_to(undef, 'view', 'project')} : ();
    my %m_rights = $self->user ? map {$_, 1} @{$self->user->has_right_to(undef, 'view', 'metagenome')} : ();
    map { $p_rights{$_} = 1 } @{ $master->Project->get_public_projects(1) };
    map { $m_rights{$_} = 1 } @{ $master->Job->get_public_jobs(1) };

    # get unique list of mgids based on user rights and inputed ids
    foreach my $id (@ids) {
        next if (exists $seen->{$id});
        if ($id =~ /^mgm(\d+\.\d+)$/) {
            if (exists($m_rights{'*'}) || exists($m_rights{$1})) {
    	        $mgids->{$1} = 1;
            } else {
                $self->return_data( {"ERROR" => "insufficient permissions in matrix call for id: ".$id}, 401 );
            }
        } elsif ($id =~ /^mgp(\d+)$/) {
            if (exists($p_rights{'*'}) || exists($p_rights{$1})) {
    	        my $proj = $master->Project->init( {id => $1} );
    	        foreach my $mgid (@{ $proj->metagenomes(1) }) {
    	            next unless (exists($m_rights{'*'}) || exists($m_rights{$mgid}));
    	            $mgids->{$mgid} = 1;
    	        }
            } else {
                $self->return_data( {"ERROR" => "insufficient permissions in matrix call for id: ".$id}, 401 );
            }
        } else {
            $self->return_data( {"ERROR" => "unknown id in matrix call: ".$id}, 401 );
        }
        $seen->{$id} = 1;
    }
    if (scalar(keys %$mgids) == 0) {
        $self->return_data( {"ERROR" => "no valid ids submitted and/or found: ".join(", ", @ids)}, 401 );
    }

    # prepare data
    my $data = $self->prepare_data([keys %$mgids], $type);
    $self->return_data($data);
}

# reformat the data into the requested output format
sub prepare_data {
    my ($self, $data, $type) = @_;
    
    # get optional params
    my $cgi = $self->cgi;
    my $source = $cgi->param('source') ? $cgi->param('source') : (($type eq 'organism') ? 'M5NR' : (($type eq 'function') ? 'Subsystems': 'RefSeq'));
    my $rtype  = $cgi->param('result_type') ? $cgi->param('result_type') : 'abundance';
    my $glvl   = $cgi->param('group_level') ? $cgi->param('group_level') : (($type eq 'organism') ? 'strain' : 'function');
    my $all_srcs  = {};
    my $leaf_node = 0;

    # initialize analysis obj with mgids
    my $master = $self->connect_to_datasource();
    my $mgdb   = MGRAST::Analysis->new( $master->db_handle );
    unless (ref($mgdb)) {
        $self->return_data({"ERROR" => "could not connect to analysis database"}, 500);
    }
    $mgdb->set_jobs($data);

    # controlled vocabulary set
    my $result_idx = { abundance => {function => 3, organism => 10, feature => 2},
    		           evalue    => {function => 5, organism => 12, feature => 3},
    		           length    => {function => 7, organism => 14, feature => 5},
    		           identity  => {function => 9, organism => 16, feature => 7}
    		         };
    my $result_map = {abundance => 'abundance', evalue => 'exp_avg', length => 'len_avg', identity => 'ident_avg'};
    my @func_hier  = map { $_->[0] } @{$self->{hierarchy}{ontology}};
    my @org_hier   = map { $_->[0] } @{$self->{hierarchy}{organism}};
    my $type_set   = ["function", "organism", "feature"];
    		         
    # validate controlled vocabulary params
    unless (exists $result_map->{$rtype}) {
        $self->return_data({"ERROR" => "invalid result_type for matrix call: ".$rtype." - valid types are [".join(", ", keys %$result_map)."]"}, 500);
    }
    if ($type eq 'organism') {
        map { $all_srcs->{$_->[0]} = 1 } @{$mgdb->sources_for_type('protein')};
        map { $all_srcs->{$_->[0]} = 1 } @{$mgdb->sources_for_type('rna')};
        if ( grep(/^$glvl$/, @org_hier) ) {
            $glvl = 'tax_'.$glvl;
            if ($glvl eq 'tax_strain') {
  	            $glvl = 'name';
  	            $leaf_node = 1;
            }
        } else {
            $self->return_data({"ERROR" => "invalid group_level for matrix call of type ".$type.": ".$glvl." - valid types are [".join(", ", @org_hier)."]"}, 500);
        }
    } elsif ($type eq 'function') {
        map { $all_srcs->{$_->[0]} = 1 } grep { $_->[0] !~ /^GO/ } @{$mgdb->sources_for_type('ontology')};
        if ( grep(/^$glvl$/, @func_hier) ) {
            if ($glvl eq 'function') {
  	            $glvl = ($source =~ /^[NC]OG$/) ? 'level3' : 'level4';
            }
            if ( ($glvl eq 'level4') || (($source =~ /^[NC]OG$/) && ($glvl eq 'level3')) ) {
  	            $leaf_node = 1;
            }
        } else {
            $self->return_data({"ERROR" => "invalid group_level for matrix call of type ".$type.": ".$glvl." - valid types are [".join(", ", @func_hier)."]"}, 500);
        }
    } elsif ($type eq 'feature') {
        map { $all_srcs->{$_->[0]} = 1 } @{$mgdb->sources_for_type('protein')};
        map { $all_srcs->{$_->[0]} = 1 } @{$mgdb->sources_for_type('rna')};
        delete $all_srcs->{M5NR};
        delete $all_srcs->{M5RNA};
    }
    unless (exists $all_srcs->{$source}) {
        $self->return_data({"ERROR" => "invalid source for matrix call of type ".$type.": ".$source." - valid types are [".join(", ", keys %$all_srcs)."]"}, 500);
    }

    # get data
    my $md52id  = {};
    my $ttype   = '';
    my $mtype   = '';
    my $matrix  = []; # [ row <annotation>, col <mgid>, value ]
    my $col_idx = $result_idx->{$rtype}{$type};

    if ($type eq 'organism') {
        $ttype = 'Taxon';
        $mtype = 'taxonomy';
        if ($leaf_node) {
            my (undef, $info) = $mgdb->get_organisms_for_sources([$source]);
            # mgid, source, tax_domain, tax_phylum, tax_class, tax_order, tax_family, tax_genus, tax_species, name, abundance, sub_abundance, exp_avg, exp_stdv, ident_avg, ident_stdv, len_avg, len_stdv, md5s
            @$matrix = map {[ $_->[9], $_->[0], $self->toNum($_->[$col_idx], $rtype) ]} @$info;
            map { $self->{org2tax}->{$_->[9]} = [ @$_[2..9] ] } @$info;
        } else {
            @$matrix = map {[ $_->[1], $_->[0], $self->toNum($_->[2], $rtype) ]} @{$mgdb->get_abundance_for_tax_level($glvl, undef, [$source], $result_map->{$rtype})};
            # mgid, hier_annotation, value
        }
    } elsif ($type eq 'function') {
        $ttype = 'Function';
        $mtype = 'ontology';
        if ($leaf_node) {
            my (undef, $info) = $mgdb->get_ontology_for_source($source);
            # mgid, id, annotation, abundance, sub_abundance, exp_avg, exp_stdv, ident_avg, ident_stdv, len_avg, len_stdv, md5s
            @$matrix = map {[ $_->[1], $_->[0], $self->toNum($_->[$col_idx], $rtype) ]} @$info;
        } else {
            @$matrix = map {[ $_->[1], $_->[0], $self->toNum($_->[2], $rtype) ]} @{$mgdb->get_abundance_for_ontol_level($glvl, undef, $source, $result_map->{$rtype})};
            # mgid, hier_annotation, value
        }
    } elsif ($type eq 'feature') {
        $ttype = 'Gene';
        $mtype = $source.' ID';
        my $info = $mgdb->get_md5_data(undef, undef, undef, undef, 1);
        # mgid, md5, abundance, exp_avg, exp_stdv, ident_avg, ident_stdv, len_avg, len_stdv, seek, length
        my %md5s = map { $_->[1], 1 } @$info;
        my $mmap = $mgdb->decode_annotation('md5', [keys %md5s]);
        map { push @{$md52id->{ $mmap->{$_->[1]} }}, $_->[0] } @{ $mgdb->annotation_for_md5s([keys %md5s], [$source]) };
        @$matrix = map {[ $_->[1], $_->[0], $self->toNum($_->[$col_idx], $rtype) ]} grep {exists $md52id->{$_->[1]}} @$info;
    }

    @$matrix = sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @$matrix;
    my $row_ids = $self->sorted_hash($matrix, 0);
    my $col_ids = $self->sorted_hash($matrix, 1);

    # produce output
    my $brows = [];
    my $bcols = [];
    my $r_map = ($type eq 'feature') ? $md52id : $self->get_hierarchy($mgdb, $type, $glvl, $source, $leaf_node);
    foreach my $rid (sort {$row_ids->{$a} <=> $row_ids->{$b}} keys %$row_ids) {
        my $rmd = exists($r_map->{$rid}) ? { $mtype => $r_map->{$rid} } : undef;
        push @$brows, { id => $rid, metadata => $rmd };
    }
    my $mddb = MGRAST::Metadata->new();
    my $meta = $mddb->get_jobs_metadata_fast([keys %$col_ids], 1);
    foreach my $cid (sort {$col_ids->{$a} <=> $col_ids->{$b}} keys %$col_ids) {
        my $cmd = exists($meta->{$cid}) ? $meta->{$cid} : undef;
        push @$bcols, { id => 'mgm'.$cid, metadata => $cmd };
    }
    
    my $obj = { "id"                   => join(";", map { $_->{id} } @$bcols).'_'.$glvl.'_'.$source.'_'.$rtype,
  		        "format"               => "Biological Observation Matrix 1.0",
  		        "format_url"           => "http://biom-format.org",
  		        "type"                 => $ttype." table",
  		        "generated_by"         => "MG-RAST revision ".$Conf::server_version,
  		        "date"                 => strftime("%Y-%m-%dT%H:%M:%S", localtime),
  		        "matrix_type"          => "sparse",
  		        "matrix_element_type"  => ($rtype eq 'abundance') ? "int" : "float",
  		        "matrix_element_value" => $rtype,
  		        "shape"                => [ scalar(keys %$row_ids), scalar(keys %$col_ids) ],
  		        "rows"                 => $brows,
  		        "columns"              => $bcols,
  		        "data"                 => $self->index_sparse_matrix($matrix, $row_ids, $col_ids)
  		      };
  		      
    return $obj;
}

sub get_hierarchy {
    my ($self, $mgdb, $type, $level, $src, $leaf_node) = @_;
    if ($type eq 'organism') {
        return $leaf_node ? $self->{org2tax} : $mgdb->ach->get_taxonomy4level_full($level, 1);
    } elsif ($type eq 'function') {
        return $leaf_node ? $mgdb->ach->get_all_ontology4source_hash($src) : $mgdb->ach->get_level4ontology_full($src, $level, 1);
    } else {
        return {};
    }
}

sub index_sparse_matrix {
    my ($self, $matrix, $rows, $cols) = @_;
    my $sparse = [];
    foreach my $pos (@$matrix) {
        my ($r, $c, $v) = @$pos;
        push @$sparse, [ $rows->{$r}, $cols->{$c}, $v ];
    }
    return $sparse;
}

sub sorted_hash {
    my ($self, $array, $idx) = @_;
    my $pos = 0;
    my $out = {};
    my @sub = sort map { $_->[$idx] } @$array;
    foreach my $x (@sub) {
        next if (exists $out->{$x});
        $out->{$x} = $pos;
        $pos += 1;
    }
    return $out;
}

1;
