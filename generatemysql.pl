#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Getopt::Long;
use Data::Dumper;
use Pod::Usage;

# global options
my $help;   # help text
my $file;   # input file
my $DEBUG;  # debug flag

# database handles;
my $dsn;
my $dbh;

my @records = (
    { 'name' => '',     'type' => 'SOA',  'content' => 'vic20.blipp.com pawal.blipp.com 1', 'ttl' => '86400' },
    { 'name' => '',     'type' => 'NS',   'content' => 'ns1.loopia.se', 'ttl' => '86400' },
    { 'name' => '',     'type' => 'NS',   'content' => 'ns2.loopia.se', 'ttl' => '86400' },
    { 'name' => '',     'type' => 'MX',   'content' => 'mail.loopia.se', 'ttl' => '86400' },
    { 'name' => 'www.', 'type' => 'A',    'content' => '192.195.142.21', 'ttl' => '86400' },
    { 'name' => 'www.', 'type' => 'AAAA', 'content' => '2001:16d8:ff00:2a9::2', 'ttl' => '86400' },
    { 'name' => 'foo.', 'type' => 'AAAA', 'content' => '2001:16d8:ff00:2a9::2', 'ttl' => '86400' },
    { 'name' => 'bar.', 'type' => 'A',    'content' => '192.195.142.21', 'ttl' => '86400' },
    { 'name' => 'zzz.', 'type' => 'A',    'content' => '192.195.142.21', 'ttl' => '86400' },
);

# read files;
sub readfile {
    my $file = shift;
    my @domains;

    open(FILE, "<$file") or die "can't read file: $file";
    while (<FILE>) {
	print if $DEBUG;
	chomp $_;
	push @domains, $_;
    }
    return \@domains;
}

sub genSQL {
    my $domains = shift;
    my $domainid = 0;
    my $domaintype = 'NATIVE';
    my $start = 'START TRANSACTION;';
    my $sth = $dbh->prepare('START TRANSACTION');
    $sth->execute;
    foreach my $domain (@$domains) {
	$sth = $dbh->prepare("INSERT INTO domains (id,name,type) VALUES (0, \"$domain\", \"$domaintype\");");
	$sth->execute;
	$domainid = $dbh->{'mysql_insertid'}."\n";
	chomp $domainid;
	foreach my $rr (@records) {
	    my $name = $rr->{'name'}.$domain;
	    my $type = $rr->{'type'};
	    my $content = $rr->{'content'};
	    my $ttl = $rr->{'ttl'};
	    my $prio = $type eq 'MX' ? '1' : '0';
	    $sth = $dbh->prepare("INSERT INTO records (domain_id,name,type,content,ttl,prio) VALUES ".
				 "(?, ?, ?, ?, ?, ?);");
	    my $result = $sth->execute($domainid, $name, $type, $content, $ttl, $prio);
	}
	print "$domain: $domainid created\n";
    }
    $sth = $dbh->prepare('COMMIT');
    $sth->execute;
}

#my $sth = $dbh->prepare("SELECT * FROM records");
#$sth->execute();
#while (my $ref = $sth->fetchrow_hashref()) {
#    print "Found a row: id = $ref->{'id'}, name = $ref->{'name'}\n";
#}
#$sth->finish();


sub main() {
    my $help = 0;
    GetOptions('help|h' => \$help,
               'file|f=s' => \$file,
               'debug' => \$DEBUG,
	) or pod2usage(2);
    pod2usage(1) if($help);
    pod2usage(1) if(not defined $file);

    $dsn = "DBI:mysql:database=powerdns;host=localhost;port=3306";
    $dbh = DBI->connect($dsn, 'powerdns', 'powerdnspassword');

    my $domains = readfile($file);
    genSQL($domains);
}

main;

=head1 NAME

generatemysql.pl

=head1 SYNOPSIS

   generatemysql.pl -f domainfile.txt

=head1 DESCRIPTION

   Reads a list of domains from a file and generates SQL inserts
   for a PowerDNS MySQL db and runs them in one transaction. Also
   adds zone content for these domains.

=head1 AUTHOR

   Patrik Wallstrom <pawal@blipp.com>

=cut
