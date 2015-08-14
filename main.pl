#!/bin/perl -w

use strict;
use warnings;

use lib "./Crawler";
use Crawler;


Crawler->new("https://super6.skysports.com", ["http://skybet.com", "https://www.skybet.com"], 10)->visit();
