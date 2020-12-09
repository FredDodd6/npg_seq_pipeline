#!/usr/bin/env perl
use Test::More tests => 6;
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
                                                  submission_org => undef
                                                 },
                          'MILK-AB7F7A' => {
                                                  central_sample_id =>"MILK-AB7F7A",
                                                  submission_org => undef
                                                }
                                },
                    NT1648726P=>{
                          'MILK-AB7D8F' =>  {
                                                  central_sample_id => "MILK-AB7D8F",
                                                  submission_org => undef
                                                },
                          'MILK-AB7772' => {
                                                  central_sample_id => "MILK-AB7772",
                                                  submission_org => undef
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


#using compact json with ALL submission_org = 1
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"me.id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 

print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));

update_metadata($test_rs,$ds_ref);

print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));






#using ds with no biosample
#refresh database
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 

print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));


update_metadata($test_rs,$no_biosample_ref);
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 
print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));


#using empty ds
#refresh database
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 

print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));

update_metadata($test_rs,$empty_ref);
my $test_rs =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 
print (Dumper([map{$_->iseq_heron_product_metric->cog_sample_meta}$test_rs->all()]));

ok(defined $test_rs, "last test");#temporary check
done_testing();

