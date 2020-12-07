#!/usr/bin/env perl
use Test::More tests => 7;
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

#example run
my $id_run = 35340;
my $schema =npg_tracking::Schema->connect();
my $mlwh_schema=WTSI::DNAP::Warehouse::Schema->connect();

my ($fn,$rs) = get_table_info_for_id_run($id_run,$schema,$mlwh_schema);
my %ds = json_to_structure($short_json_string,$fn);
my $ds_ref = \%ds;

######

ok(defined $fn, "folder name is defined");
ok($fn eq "201102_A00950_0194_AHTJJKDRXX", "folder name is correct");
ok($rs == 770, "correct number of rows in result set");

#########
ok(defined $ds_ref, "structure is returned");

#expected structure from simplified json output
my $hardcoded_ds= ({NT1648725O=> {
                          'CAMC-AB113E' =>  {
                                                  central_sample_id =>"CAMC-AB113E",
                                                  submission_org => undef
                                                 },
                          'CAMC-AB114D' => {
                                                  central_sample_id =>"CAMC-AB114D",
                                                  submission_org => undef
                                                }
                                },
                    NT1648726P=>{
                          'CAMC-AAF959' =>  {
                                                  central_sample_id => "CAMC-AAF959",
                                                  submission_org => undef
                                                },
                          'CAMC-AAF968' => {
                                                  central_sample_id => "CAMC-AAF968",
                                                  submission_org => undef
                                                }
                              }
                   });
is_deeply( $ds_ref ,$hardcoded_ds,"Data structure is correct format");    

#update_metadata($rs,$ds_ref);
#testing update_metada method
####
my $test_schema=t::dbic_util->new()->test_schema_mlwh('t/data/fixtures/mlwh-majora');
my $s = $test_schema->resultset(q(IseqHeronProductMetric));


my $s =$test_schema->resultset("IseqProductMetric")->search({"id_run" => $id_run},{join=>{"iseq_flowcell" => "sample"}}); 


my ($fn2,$rs2) = get_table_info_for_id_run($id_run,$schema,$test_schema);

print $fn2. "filename from test database \n";


######
  #feed in different data structures where :
  #submission_org is 1 or 0
  # there is no biosample for library
  # there is no library for given run
  ##### 


done_testing();

