#!/usr/bin/perl

=encoding utf-8

=head1 NAME

validate-against-schema.pl -- Validates YAML files against a JSON schema in YAML format.

=head1 SYNOPSIS

validate-against-schema.pl [-v] -s=<SCHEMA> file.yml [ ... ]

=head1 OPTIONS

=over 4

=item B<< -s <SCHEMA> >>

JSON schema file (in YAML format).

=item B<-v>

Verbose output to C<STDERR>.

=item B<-?>, B<-help>, B<-h>, B<-man>

Print help and exit.

=back

=head1 SEE ALSO

JSON schema specifiation: L<https://json-schema.org/specification.html>.

=head1 AUTHOR

Frank Wiegand, L<mailto:wiegand@bbaw.de>, 2022.

=cut

use 5.012;
use warnings;

use Getopt::Long;
use JSON::PP;
use JSON::Schema::Modern;
use Pod::Usage;
use YAML::PP;

my ($verbose, $man, $help, $schema_file);
GetOptions(
    'schema=s' => \$schema_file,
    'v+'       => \$verbose,
    'vv'       => sub { $verbose += 2 },
    'help|?'   => \$help,
    'man|h'    => \$man,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;
die '-s ... missing' unless $schema_file;
die 'no files to check' unless @ARGV;

my $ypp = YAML::PP->new(
    schema  => [qw(Core Merge)],
    boolean => 'JSON::PP',
);

my $yaml_schema = $ypp->load_file( $schema_file );

my $js = JSON::Schema::Modern->new(
    output_format => 'flag',
    validate_formats => 1,
);

foreach my $file ( @ARGV ) {
    my $yaml_config = $ypp->load_file( $file );
    my $result = $js->evaluate( $yaml_config, $yaml_schema );
    my @errors = $result->errors;
    say sprintf "%s: %s", $file, $result;
}

__END__
