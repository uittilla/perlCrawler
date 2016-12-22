#!/bin/perl -w

use strict;
use warnings;
use Beanstalk::Client;
use JSON;
use Data::Dumper;

use lib "./Crawler";
use Crawler;

my $json   = JSON->new->allow_nonref;
my $client = Beanstalk::Client->new({
    server       => "localhost",
    default_tube => 'links',
});
my $entry;
my $job;
my $stats = $client->stats_tube('links');

while($stats->{'current-jobs-ready'} > 0) {
    $job   = $client->reserve;
    $entry = $json->decode( $job->data );

    print $entry->{link} . "\n";
    Crawler->new($entry->{link}, $entry->{targets} , $entry->{max_links})->visit();

    $job->delete($job->id);
}
