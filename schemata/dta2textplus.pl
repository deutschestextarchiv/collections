#!/usr/bin/perl

=encoding utf-8

=head1 NAME

dta2textplus.pl -- Converts DTA metadata to Text+ metadata.

=head1 SYNOPSIS

dta2textplus.pl [-v] -i file.yml [ ... ]

=head1 OPTIONS

=over 4

=item B<-v>

Verbose output to C<STDERR>.

=item B<-?>, B<-help>, B<-h>, B<-man>

Print help and exit.

=back

=head1 SEE ALSO

The Text+ Registry Models at L<https://gitlab.com/minfba/resinfra/textplus-registry-models>.

=head1 AUTHOR

Frank Wiegand, L<mailto:wiegand@bbaw.de>, 2024.

=cut

use 5.012;
use warnings;
use utf8;

use FindBin;
use Getopt::Long;
use JSON::PP;
use Pod::Usage;

my ($verbose, $man, $help, $input);
GetOptions(
    'input=s' => \$input,
    'v+'      => \$verbose,
    'vv'      => sub { $verbose += 2 },
    'help|?'  => \$help,
    'man|h'   => \$man,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;
die '-i=... missing' unless $input;

my $in = join '' => `perl $FindBin::Bin/compile-catalog.pl -s $input`;

$in = decode_json($in) or die $@;

my %out = (
    inhaltliche_angaben => {
        titel                  => $in->{title}{name},
        beschreibung           => $in->{description},
        größe                  => sprintf('%d documents, %d tokens', $in->{numbers}{documents}, $in->{numbers}{tokens}),
        lizenz                 => $in->{availability}{name},
        'lizenz-url'           => $in->{availability}{url},
        modalität              => $in->{modality},
        sprache                => [ map { $_->{iso} } @{$in->{languages}} ],
        datentyp               => [ qw(collection corpus) ], # vocabulary
        erstellungsdatum       => undef, # not yet in DTA
        veröffentlichungsdatum => undef, # not yet in DTA
        abgedeckter_zeitraum   => sprintf('%s-%s', $in->{timeCoverage}{start}, $in->{timeCoverage}{end}),
        volltext_verfügbar     => 'available', # vocabulary
        annotationslayer => [
            {
                typ                 => 'text',
                manuell_automatisch => 'manuell', # does not apply to OCR?
                umfang              => 'komplett',
            },
            {
                typ                 => 'lemma',
                manuell_automatisch => 'automatisch',
                umfang              => 'komplett',
            },
            {
                typ                 => 'orth',
                manuell_automatisch => 'automatisch',
                umfang              => 'komplett',
            },
            {
                typ                 => 'norm',
                manuell_automatisch => 'automatisch',
                umfang              => 'komplett',
            },
            {
                typ                 => 'pos', # vocabulary says: pos (UD17)
                manuell_automatisch => 'automatisch',
                umfang              => 'komplett',
            },
        ],
        # cf. https://gitlab.com/minfba/resinfra/textplus-registry-models/-/blob/main/vocabulary_entries/collections_typ.json?ref_type=heads
        kollektionstyp         => 'unbestimmt',
        genre                  => [ map { $_->{sub} ? sprintf('%s::%s', $_->{main}, $_->{sub}) : $_->{main} } @{$in->{genre}} ],
        fachliche_zuordnung    => undef, # TODO?
        schlagworte            => [ @{$in->{keywords}} ],
    },
    technische_angaben => {
        pid                      => undef, # not yet in DTA
        zugang                   => undef, # unclear
        hierarchie               => undef,
        bezug                    => undef,
        dateien_datenströme      => undef, # unclear
        technische_dokumentation => undef, # should maybe lead to DTA landing page?
    },
    organisatorische_angaben => {
        datenverantwortliche_person      => $in->{association}{editors}[0],  # TBD
        datenverantwortliche_institution => $in->{association}{institution}, # TBD
        ansprechperson                   => undef, # not (yet?) in DTA
        förderer                         => undef, # not in DTA
        förderer_id                      => undef, # not in DTA
        projekttitel                     => $in->{project}{name},
    },
);

say encode_json(\%out);
__END__
