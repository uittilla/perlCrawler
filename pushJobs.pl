#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Beanstalk::Client;
use JSON;
use Data::Dumper;

my $client = Beanstalk::Client->new({
    server       => "localhost",
    default_tube => 'links',
});

my %jobs = (
    1 => {
        "job" => {
            "link"      => "http://www.golf365.com/features_story/0,17923,15870_5997668,00.html",
            "targets"   => [ "http://www.skybet.com", "https://www.skybet.com" ],
            "max_links" => "50"
        },
        "priority" => 1
    },
    2 => {
        "job" => {
            "link"      => "http://www.football-league.co.uk/sky-bet-championship/news/",
            "targets"   => [ "http://www.skybet.com", "https://www.skybet.com" ],
            "max_links" => "10"
        },
        "priority" => 5
    },
    3 => {
        "job" => {
            "link"      => "http://www.skysports.com/",
            "targets"   => [ "http://www.skybet.com", "https://www.skybet.com" ],
            "max_links" => "100"
        },
        "priority" => 3
    },
    4 => {
        "job" => {
            "link"      => "http://www.teamtalk.com/",
            "targets"   => [ "http://www.skybet.com", "https://www.skybet.com" ],
            "max_links" => "20"
        },
        "priority" => 5
    },
    5 => {
        "job" => {
            "link"      => "http://www.online-betting.me.uk/",
            "targets"   => [ "http://www.skybet.com", "https://www.skybet.com" ],
            "max_links" => "10"
        },
        "priority" => 10
    },
);

my $json = JSON->new->allow_nonref;

while (my ($k, $v) = each %jobs) {
    $client->put({
        data     => $json->encode($v->{job}),
        priority => $v->{priority},
        ttr      => 120,
        delay    => 5,
    });
}
