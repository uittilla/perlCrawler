#!/usr/bin/perl
# Author Mark Ibbotson (Ibbo) <mark.ibbotson@stickyeyes.com>
# Mysql DBI interface

package Mysql;

use 5.010;
use strict;
use warnings;
use DBI;
use Data::Dumper;

our $VERSION = '0.01';

# constructor
sub new {
    my ($class) = @_;
    my $self = bless {},$class;
    
    $self->{_dbh} = DBI->connect("DBI:mysql:database=backlink_audit_tool;host=localhost", 
                       'root','secret', { RaiseError => 1 } ) or die ( "Couldn't connect to database: " . DBI->errstr );
    
    return $self;
}

# Test
sub showDatabase {
    my $self = shift;
    my $sql  = "show tables";
    my $sth  = $self->{_dbh}->prepare($sql);
        
    $sth->execute();
    
    return $sth;
}

# Update backlink redirect info
sub updateRedirect {
    my ($self, $status, $uri, $host) = @_;
    my $sql  = "update backlinks set status_code = ?, redirected_url = ? where url = ?"; 
    my $sth  = $self->{_dbh}->prepare($sql);

    $sth->bind_param( 1, $status );
    $sth->bind_param( 2, $uri    );
    $sth->bind_param( 3, $host   );
    $sth->execute();
    
    return $sth;
}

# Update backlink status 
sub updateStatus {
    my ($self, $status, $url) = @_;
    my $sql  = "update backlinks set status_code = ? where url = ?";
    my $sth  = $self->{_dbh}->prepare($sql);
   
    $sth->bind_param( 1, $status );
    $sth->bind_param( 2, $url    );
    $sth->execute();
    
    return $sth;    
}

# Adds backlink matched target
sub addTarget {
    my ($self, $host, $link, $position, $anchor) = @_;
    my $sql  = "INSERT IGNORE INTO target_urls (backlink_url_id, url_id, url, url_position_index, anchor_text) VALUES (unhex(md5(?)), unhex(md5(?)), ?, ?, ?)";
    my $sth  = $self->{_dbh}->prepare($sql);
   

    $sth->bind_param( 1, $host     );
    $sth->bind_param( 2, $link     );
    $sth->bind_param( 3, $link     );
    $sth->bind_param( 4, $position );
    $sth->bind_param( 5, $anchor   );
    $sth->execute();
    
    return $sth;
}

# Add job results
sub addEntry {
    my ($self, $crawled, $max, $total, $url) = @_;
    my $sql  = "update backlinks set sitewide_crawled_pages = ?, sitewide_max_links_per_page = ?, sitewide_total_links_found = ? where url = ?";
    my $sth  = $self->{_dbh}->prepare($sql);
    
    $sth->bind_param( 1, $crawled );
    $sth->bind_param( 2, $max     );    
    $sth->bind_param( 3, $total   );    
    $sth->bind_param( 4, $url     );     
    $sth->execute();
    
    return $sth;
}

# get master Urls
sub getMasters {
    my $self = shift;
    my $sql  = "select url from master_urls";
    my $sth  = $self->{_dbh}->prepare($sql);
    
    $sth->execute();
    
    return $sth;  
}

# Sets link error
sub setError {
    my ($self, $url) = @_;
    my $sql = "update backlinks set status_code = 0 where url = ?";
    my $sth = $self->{_dbh}->prepare($sql);
    
    $sth->bind_param( 1, $url );
    $sth->execute();
    
    return $sth;   
}

1;
