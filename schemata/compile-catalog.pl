#!/usr/bin/perl

use 5.012;
use warnings;

use File::Basename 'fileparse';
use File::Path 'make_path';
use Getopt::Long;
use JSON::PP;
use LWP::UserAgent::Cached;
use URI::Escape 'uri_escape_utf8';
use YAML::PP;

my ($single, $no_cache);
my $cache_dir = '/tmp/lwp-cache';
GetOptions(
    's' => \$single,
    'no-cache' => \$no_cache,
    'cache-dir=s' => \$cache_dir,
) or die("Error in command line arguments\n");

make_path($cache_dir) unless $no_cache;

my $ypp = YAML::PP->new(
    schema  => [qw(Core Merge)],
    boolean => 'JSON::PP',
);

my $ua = LWP::UserAgent::Cached->new( $no_cache ? () : (cache_dir => $cache_dir) );
my %stat_files = (
    tokens    => 'ddc.tokens.all.txt',
    sentences => 'ddc.sentences.all.txt',
    documents => 'ddc.files.all.txt',
);
my $dstar_base = 'https://ddc.dwds.de/dstar/';

my %stat_queries = (
    tokens    => 'COUNT(* #SEP #HAS[flags,/\b%s\b/])',
    sentences => 'COUNT(* #JOIN #HAS[flags,/\b%s\b/])',
    documents => 'COUNT(* #WITHIN file #HAS[flags,/\b%s\b/])',
);

my %out;
my $i = 0;

FILE:
  foreach my $file ( @ARGV ) {
    my ($base, $dir, $suffix) = fileparse $file, '.yml';
    my ($src) = $dir =~ m{([^/]+)/$};

    say STDERR "$base: processing ...";
    my $yaml = $ypp->load_file( $file );

    $yaml->{src} = $src;

    next unless exists $yaml->{dstar};
    my $corpus = $yaml->{dstar}{corpus};
    next unless $corpus;

    next if exists $yaml->{status} and $yaml->{status} eq 'wip';

    my $flags = $yaml->{dstar}{flags};
    if ( $flags ) {
        # DDC queries
        while ( my ($k, $v) = each %stat_queries ) {
            my $url = sprintf '%s%s/dstar.perl?q=%s&fmt=text', $dstar_base, uri_escape_utf8($corpus), uri_escape_utf8(sprintf($v, $flags));
            say STDERR "fetching $url ...";
            my $res = $ua->get($url);
            if ( !$res->is_success ) {
                say STDERR "$url: ".$res->status_line;
                next FILE;
            }
            if ( $res->content =~ /no hits/ ) {
                say STDERR "$base: no token numbers, skipping ...";
                next FILE;
            }
            my ($number) = split /\s+/ => $res->content;
            $yaml->{numbers}{$k} = $number;
        }
    }
    else {
        # grab stat files directly, should be much faster
        while ( my ($k, $v) = each %stat_files ) {
            my $url = sprintf '%s%s/stats/%s', $dstar_base, $corpus, $v;
            say STDERR "fetching $url ...";
            my $res = $ua->get($url);
            if ( !$res->is_success ) {
                say STDERR "$url: ".$res->status_line;
                next FILE;
            }
            my ($number) = split /\s+/ => $res->content;
            $yaml->{numbers}{$k} = $number;
        }
    }

    if ( $single ) {
        say encode_json($yaml);
        exit;
    }

    $out{ $base } = $yaml;
    $i++;
}

say encode_json(\%out);

__END__
