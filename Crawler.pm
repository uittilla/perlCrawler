#!/usr/bin/perl
# Author:  Mark Ibbotson
# Purpose: Demo the ease of crawling in perl, there are many ways to skin a cat
# OK:      Its in perl and the syntax can be enough to put any man jack off
# BUT:     Look it less than 100 lines  
# http://search.cpan.org/~ether/WWW-Mechanize-1.73/lib/WWW/Mechanize.pm
# apt-get install libwww-mechanize-perl
package Crawler;

use strict;
use warnings;
use WWW::Mechanize;
use HTML::TokeParser;
use Data::Dumper;
our $VERSION = '0.01';

# constructor
sub new {
    my ($class, $url, $target) = @_;
    my $self = bless {},$class;
    
    $self->{agent}    = WWW::Mechanize->new();   # Crawler Library     
    $self->{url}      = $url;                    # The link to spider
    $self->{target}   = $target;                 # Match the target
    $self->{matches}  = [];                      # Storage for our target matches 
    $self->{pending}  = [];                      # Nice clean no dupes array
    $self->{maxLinks} = 25;                      # Max pages 
    $self->{timeout}  = 5;                       # Timeout for each page visit (dont kill them) 
    
    $self->{agent}->max_redirect(1);
    
    push(@{$self->{pending}}, $self->{url});    # Dont duplicate
    
    return $self;
}

# Visit link and find new links to vist and any targets
sub visit {
    my ($self) = @_;
    
    $| = 1;                                                                 # Page autorefresh
    my $scanned = 0;                                                        # Tracked how manay pages we have viewed
    
    my %link_tracker = map { $_ => 1 } $self->{pending};                   # Keep track of what links we've found already.
    
    # This is just too damned easy
    while (my $queued_link = pop @{$self->{pending}}) {
         
        $self->{agent}->get($queued_link);                                  # Get the page
        
        if($scanned < $self->{maxLinks}) {  
            my @links   = $self->{agent}->find_all_links(                   # Find internal links
                                url_abs_regex => qr/^\Q$self->{url}\E/,    
                                tag           => 'a'
                          );
                          
	    my @matches = $self->{agent}->find_all_links(                   # Find any Targets 
	                        url_regex => qr/^\Q$self->{target}\E/, 
	                        tag       => 'a'
	                  ); 
		
	    for my $new_link (@links) {                                     # Populate our links to view array
		if($new_link->url_abs() !~ /#/) {                           # Skip links with #someTag
		    push @{$self->{pending}}, $new_link->url_abs()          # Add the new link 
		         unless $link_tracker{$new_link->url_abs()}++;      # Unless it already exists 
	        }
            }
            
            foreach my $matched (@matches) {                                # Populate matches
		 push @{$self->{matches}}, $matched;   
	    }            
        }
        else {
            print "\n";		
            foreach(@{$self->{matches}}) {
		print "Link: ", $_->url(), " Anchor: ", $_->text(), " Found on: ", $_->base(), "\n";
	    }
            exit;		
	}
        
        sleep($self->{timeout});
        
        printf "\rPages scanned: [%d] Unique Links: [%s] Queued: [%s] Matched [%s]", ++$scanned, scalar keys %link_tracker, scalar @{$self->{pending}}, scalar @{$self->{matches}};
    }
}
1;

Crawler->new("http://www.zipleaf.co.uk/GoToWebsite/1188354", "http://www.antler.co.uk")->visit();