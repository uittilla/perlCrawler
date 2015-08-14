#!/usr/bin/perl
# Author:  Mark Ibbotson
# Purpose: Demo the ease of crawling in perl, there are many ways to skin a cat
# OK:      Its in perl and the syntax can be enough to put any man jack off
# TODO:    Needs to handle redirects, etc but check out the CPAN page below for this is already done in this lib.
# http://search.cpan.org/~ether/WWW-Mechanize-1.73/lib/WWW/Mechanize.pm
# apt-get install libwww-mechanize-perl
# Fear not the Perl, overcome and embrace it

package Crawler;

use strict;
use warnings;
use WWW::Mechanize;
use URI;
use Data::Dumper;
our $VERSION = '0.01';

$| = 1;         # Page autorefresh

# constructor
sub new {
    my ($class, $url, $target, $maxLinks) = @_;
    my $self = bless {},$class;
    $self->{agent}    = WWW::Mechanize->new(autocheck => 0); # Crawler Library
    $self->{url}      = $url;                                # The link to spider
    $self->{hostRegX} = URI->new($url);                      # Host to match for local links
    $self->{target}   = $target;                             # Match the target
    $self->{matches}  = [];                                  # Storage for our target matches
    $self->{pending}  = [];                                  # Nice clean no dupes array
    $self->{maxLinks} = $maxLinks || 100;                    # Max pages
    $self->{timeout}  = 5;                                   # Timeout for each page visit (dont kill them)
    $self->{agent}->max_redirect(1);

    #die(print Dumper $self);

    push(@{$self->{pending}}, $self->{url});                 # Init with our landing URL

    return $self;
}

# Visit link and find new links to vist and any targets
sub visit {
    my ($self)       = @_;
    my $scanned      = 0;                                # Tracked how manay pages we have viewed
    my %link_tracker = map { $_ => 1 } $self->{pending}; # Keep track of what links we've found already.

    # This is just too damned easy
    while (my $queued_link = pop @{$self->{pending}})
    {
        $self->{agent}->get($queued_link);  # Get the page

        # Check page status
        if($self->{agent}->status() < 400) {
            if($scanned < $self->{maxLinks}) {
                 %link_tracker = $self->parseLinks(%link_tracker);
                 $self->parseTargets();
            }

            printf "\rPages scanned: [%d] Unique Links: [%s] Queued: [%s] Matched [%s]",
                    ++$scanned, scalar keys %link_tracker, scalar @{$self->{pending}}, scalar @{$self->{matches}};
        }
        else
        {
	        if(scalar keys %link_tracker == 1) {
                printf "Site unavailable [%s]\n", $queued_link;
            }
            else {
		        printf "Page not found [%s]\n", $queued_link;
            }
	    }

        if(scalar @{$self->{pending}} == 0) {
            $self->results();
            exit;
        }

        sleep($self->{timeout}); # Throttle it
    }
}

# Get Links on Page
# url_abs_regex, give it a regex link our host domain and no messing about
sub parseLinks {
   my ($self, %link_tracker) = @_;
   # Find internal links
   my $match = $self->{hostRegX}->scheme() . "://" . $self->{hostRegX}->host;
   my @links = $self->{agent}->find_all_links(url_abs_regex => qr/^\Q$match\E/, tag => 'a');

    # Populate our links to view array
    if(scalar keys %link_tracker < $self->{maxLinks}) {
	    for my $new_link (@links) {
	        # Skip links with #someTag
	        if($new_link->url_abs() !~ /#/) {
		        # Add the new link, Unless it already exists, perl magik
		        if(scalar keys %link_tracker < $self->{maxLinks}) {
		            push @{$self->{pending}}, $new_link->url_abs() unless $link_tracker{$new_link->url_abs()}++;
	            }
	        }
	    }
    }

    return %link_tracker;
}

# Get Target Url's
sub parseTargets {
    my ($self) = @_;

    my $target = $self->{target};

    # If its an array of links build the regex
    if (ref $target eq 'ARRAY') {
       $target = "(" . join('|', map { $_ } @{$target}) . ")";
    }

    # Find any Targets
    my @matches = $self->{agent}->find_all_links(url_regex => qr/^$target/, tag => 'a');

    # Populate matches
    foreach my $matched (@matches) {
	    push @{$self->{matches}}, $matched;
    }
}

sub getPending {
    my ($self) = @_;
    return $self->{pending};
}

# Output the matches
sub results {
    my ($self) = @_;
    # Show targets
    print "\n";
    foreach(@{$self->{matches}}) {
	    print "Link: ", $_->url(), " Anchor: ", $_->text(), " Found on: ", $_->base(), "\n";
    }
}

1;
