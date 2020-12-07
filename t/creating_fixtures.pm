use strict;
use warnings;
use t::dbic_util;

use WTSI::DNAP::Warehouse::Schema;
my $schema = WTSI::DNAP::Warehouse::Schema->connect();

my $rs_name = 'IseqProductMetric';
my $prs = $schema->resultset($rs_name)->search({id_run => 35340,tag_index =>[(1 .. 10)]});
print $prs->count. "\n";

my $util = t::dbic_util->new();
$util->rs_list2fixture($rs_name, [$prs], 't');

$rs_name = 'IseqFlowcell';
my @ids = map { $_->id_iseq_flowcell_tmp } $prs->all();
my $iseq_rs = $schema->resultset($rs_name)->search({id_iseq_flowcell_tmp => \@ids});

$util->rs_list2fixture($rs_name, [$iseq_rs], 't');
print $iseq_rs->count . "\n";

$rs_name = 'Sample';
my @samples = map { $_->id_sample_tmp } $iseq_rs->all();
my $sample_rs = $schema->resultset($rs_name)->search({id_sample_tmp => \@samples});
$util->rs_list2fixture($rs_name, [$sample_rs], 't');
print $sample_rs->count. "\n";

$rs_name = 'IseqHeronProductMetric';
my @ids = map { $_->id_iseq_product } $prs->all();
my $hprs = $schema->resultset($rs_name)->search({id_iseq_product => \@ids});
$util->rs_list2fixture($rs_name, [$hprs], 't');
print $hprs->count();

1;
