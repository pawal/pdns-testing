#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Pod::Usage;

# global options
my $help;         # help text
my $file;         # input file
my $DEBUG;        # debug flag
my $random = 0;   # randomness
my $nxdomain = 0; # number of nxdomain

# random globals
my @chars = ("a" .. "z", "0" .. "9");
my @types = ("SOA", "A", "AAAA", "MX", "NS");

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

sub randomString {
    my $length = shift || 3;
    my $string;
    $string .= $chars[rand @chars] for 1 .. $length;
    return $string;
}

sub randomDomain {
    my $string = randomString(16);
    $string .= ".se";
    return $string;
}

sub randomRRType {
    return $types[rand @types];
}

sub randomQuery {
    return randomDomain." ".randomRRType;
}

sub genqueries {
    my $domains = shift;
    my $i = 0; # total

    for my $domain (@$domains) {
	# existing queries
	$i++; print "www.$domain A\n";
	$i++; print "$domain NS\n";
	$i++; print "$domain MX\n";
	$i++; print "$domain DNSKEY\n";
	$i++; print "$domain SOA\n";
    }
    # add percentage of nxdomain queries for existent domains
    my $j = 0;
    for ( my $r = 0; $r < ($i * ($nxdomain / 100)); $r++ ) {
	print randomString.".".@$domains[rand @$domains]." ".randomRRType."\n";
	$j++;
    }
    $i += $j; # increase total number of queryes from added nxdomains

    # add percentage (of total) of random queries completely non-existent domains
    for ( my $r = 0; $r < ($i * ($random / 100)); $r++ ) {
	print randomQuery."\n";
    }
}

sub main() {
    my $help = 0;
    GetOptions('help|h'     => \$help,
               'file|f=s'   => \$file,
	       'random=i'   => \$random,
	       'nxdomain=i' => \$nxdomain,
               'debug'      => \$DEBUG,
        ) or pod2usage(2);
    pod2usage(1) if($help);
    pod2usage(1) if(not defined $file);

    my $domains = readfile($file);
    genqueries($domains);
}

main;

=head1 NAME

genqueries.pl

=head1 SYNOPSIS

genqueries.pl -f domainfile.txt

Mandatory arguments:

    --file           One file containing a list of domains in text format

Optional arguments:

    --nxdomain        Add percentage of NXDOMAIN queries (0 .. n) (non-existent records)
    --random          Add percentage of random queries (0 .. n) (non-existent domains)
    --help            Show this help screen
    --debug           Show debug output

=head1 DESCRIPTION

   Generates a dns query file for Nominum dnsperf from a list of domains.

=head1 AUTHOR

   Patrik Wallstrom <pawal@blipp.com>

=cut
