#!/usr/bin/perl
# Author:  Mark Ibbotson (Ibbo) <mark.ibbotson@stickyeyes.com>
# Purpose: Adds the landing page status to the DB

use 5.010;
use strict;
use warnings;

# Add working folder to library
use lib "/home/ubuntu/backlinksSaver";

use Mysql;
use Beanstalk::Client;
use JSON;

# Debug print Dumper $var
use Data::Dumper;

# Gets config file contents
my $filename  = "./config.json";
my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

# Set up JSON
my $json  = JSON->new;
my $data  = $json->decode($json_text);

# Setup Mysql
my $mysql = Mysql->new();

# Place holder for decoded job
my $scalar;

# Connect to Beanstalk
my $client = Beanstalk::Client->new(
{   server       => $data->{q_host},
    default_tube => "backlink-landing",
});

# parse tube and save entry
while(my $job = $client->reserve)
{
    $scalar = $json->decode( $job->{'data'});
    $mysql->updateStatus($scalar->{status}, $scalar->{host});
    $client->delete($job->{id});
}
