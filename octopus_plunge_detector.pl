#!/usr/bin/env perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

my $OCTOPUS_API = "https://api.octopus.energy/v1";
my $PRODUCT     = 'AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-A';

my $ua = LWP::UserAgent->new;
$ua->agent("OctopusPlungeDetector/0.1 ");

my $req = HTTP::Request->new( GET => "$OCTOPUS_API/products/$PRODUCT/standard-unit-rates/" );
my $res = $ua->request($req);

unless ( $res->is_success ) {
    print $res->status_line, "\n";
    exit 1;
}

my $data = JSON->new->utf8->decode($res->content);

use Data::Dumper;
print Dumper $data;