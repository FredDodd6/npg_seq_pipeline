#!/usr/bin/env perl
use Test::More tests => 14;
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use t::dbic_util;
use Data::Dumper; # temp

#getting npg_heron::majora module
use lib ( -d "$Bin/../lib/perl5" ? "$Bin/../lib/perl5" : "$Bin/../lib" ); 
use npg_pipeline::product::heron::majora qw/ get_table_info_for_id_run
                                             get_majora_data
                                             json_to_structure
                                             update_metadata/;
#schemas
use npg_tracking::Schema;
use WTSI::DNAP::Warehouse::Schema;

#getting short json string for testing conversion to data structure
my $short_json_string;
my $path = 't/data/majora/simple_out_compact.json';
open(my $fh, '<', $path) or die "can't open file $path";
{
  local $/;
  $short_json_string = <$fh>;
}
close($fh);

#example run with live schema
my $id_run = 35340;
my $schema =npg_tracking::Schema->connect();
my $mlwh_schema=WTSI::DNAP::Warehouse::Schema->connect();

my ($fn,$rs) = get_table_info_for_id_run($id_run,$schema,$mlwh_schema);
my %ds = json_to_structure($short_json_string,$fn);
my $ds_ref = \%ds;

#print Dumper(\$ds_ref);
######

ok(defined $fn, "folder name is defined");
ok($fn eq "201102_A00950_0194_AHTJJKDRXX", "folder name is correct");
ok($rs == 770, "correct number of rows in result set");

#########
ok(defined $ds_ref, "structure is produced");
#expected structure from simplified json output
my $hardcoded_ds= ({NT1648725O=> {
                          'MILK-AB8E21' =>  {
                                                  central_sample_id =>"MILK-AB8E21",
                                                  submission_org => "1"
                                                 },
                          'MILK-AB7F7A' => {
                                                  central_sample_id =>"MILK-AB7F7A",
                                                  submission_org => "1"
                                                }
                                },
                    NT1648726P=>{
                          'MILK-AB7D8F' =>  {
                                                  central_sample_id => "MILK-AB7D8F",
                                                  submission_org => "1"
                                                },
                          'MILK-AB7772' => {
                                                  central_sample_id => "MILK-AB7772",
                                                  submission_org => "1"
                                                }
                              }
                   });



is_deeply( $ds_ref ,$hardcoded_ds,"Data structure is correct format");    

###testing update_metada method

#different data structures to test
my %empty_ds = {};
my $empty_ref = \%empty_ds;

my %no_biosample_ds = {NT1648725O=> {},NT1648726P=>{}};
my $no_biosample_ref = \%no_biosample_ds;


#usin( compact json with ALL submission_org = 1
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"me.id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 


my @cog_meta_val_before = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());
update_metadata($test_rs,$ds_ref);
my @cog_meta_val_after = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());


my $num_values = 0;
foreach my $cog_meta_val_before (@cog_meta_val_before){
  $num_values++ if $cog_meta_val_before eq '3';
}
my $num_set = 0;
my $num_undef = 0;
foreach my $cog_meta_val_after (@cog_meta_val_after){
  $num_set++ if $cog_meta_val_after eq '1';
  $num_undef++ if $cog_meta_val_after eq undef;
}


is($num_values,20,"values before update correct");
is(scalar @cog_meta_val_after, 20, "20 cog_sample_meta values returned");
is($num_set,4, "4 values set to 1 from simple json");
is($num_undef, 16, "16 values set to undef");


#updating with no biosample
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 

my @cog_meta_val_before = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());
update_metadata($test_rs,$no_biosample_ref);
my @cog_meta_val_after = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());


my $num_values = 0;
foreach my $cog_meta_val_before (@cog_meta_val_before){
  $num_values++ if $cog_meta_val_before eq '3';
}

my $num_undef = 0;
foreach my $cog_meta_val_after (@cog_meta_val_after){
  $num_undef++ if $cog_meta_val_after eq undef;
}
is($num_values,20,"values before no biosample update correct");
is($num_undef,20,"values after no biosample update correct");

#updating with empty data structure
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 

my @cog_meta_val_before = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());
update_metadata($test_rs,$empty_ref);
my @cog_meta_val_after = (map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all());

my $num_values = 0;
foreach my $cog_meta_val_before (@cog_meta_val_before){
  $num_values++ if $cog_meta_val_before eq '3';
}

my $num_undef = 0;
foreach my $cog_meta_val_after (@cog_meta_val_after){
  $num_undef++ if $cog_meta_val_after eq undef;
}
is($num_values,20,"values before update correct");
is($num_undef,20,"all values assigned undef");

ok(defined $test_rs, "last test");#temporary check
done_testing();

