#!/usr/bin/env perl

use strict;
use warnings;
use DateTime::Format::Strptime;
use JSON;
use LWP::UserAgent;

my $OCTOPUS_API = "https://api.octopus.energy/v1";
my $PRODUCT     = 'AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-A';
my $ua          = LWP::UserAgent->new;
my $url         = "$OCTOPUS_API/products/$PRODUCT/standard-unit-rates/";
my $check_pages = 3;
my %plunge      = ();

$ua->agent("OctopusPlungeDetector/0.1");

while (1) {
    my $req = HTTP::Request->new( GET => "$url" );
    my $res = $ua->request($req);

    unless ( $res->is_success ) {
        print $res->status_line, "\n";
        exit 1;
    }

    my $data = JSON->new->utf8->decode( $res->content );

    foreach my $period ( @{ $data->{results} } ) {
        if ( $period->{value_inc_vat} <= 0 ) {
            my $key           = $period->{valid_from};
            my $format        = DateTime::Format::Strptime->new( pattern => '%FT%T%z' );
            my $dt            = $format->parse_datetime($key);
            my $value_inc_vat = $period->{value_inc_vat};
            next if $dt < DateTime->now;
            $plunge{$key}{value_inc_vat} = sprintf( "%.3fp", $value_inc_vat );
            $plunge{$key}{valid_to}      = $period->{valid_to};
        }
    }

    $url = $data->{next} // '';
    last if $url eq '' || $check_pages == 0;
    $check_pages--;
}

if ( scalar keys %plunge == 0 ) {
    exit 0;
}

foreach my $key ( sort keys %plunge ) {
    print "$key -> $plunge{$key}{valid_to}: $plunge{$key}{value_inc_vat}\n";
}
