#!/bin/perl -w

use strict;
use warnings;
use Beanstalk::Client;
use JSON;
use Data::Dumper;

use lib "./Crawler";
use Crawler;

my $client = Beanstalk::Client->new(
    {   server       => "localhost",
        default_tube => 'links',
    }
);

my $json = JSON->new->allow_nonref;
my $entry;

my $stats = $client->stats_tube('links');

while($stats->{'current-jobs-ready'} > 0) {
    my $job = $client->reserve;
    $entry = $json->decode( $job->data );
    print $entry->{link} . "\n";
    Crawler->new($entry->{link}, $entry->{targets} , $entry->{max_links})->visit();
    $job->delete($job->id);

}

#while (my $job = $client->reserve) {
#    print $job->id . "\n";

    #$entry = $json->decode( $job->data );

    #print $entry->{link} . "\n";

    #Crawler->new($entry->{link}, $entry->{targets} , 10)->visit();

    #$job->delete($job->id);
#}

#Crawler->new("http://www.skysports.com/", ["http://skybet.com", "https://www.skybet.com"], 10)->visit();
