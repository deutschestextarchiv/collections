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
if ( !ref $in or ref $in ne 'HASH' or !keys %$in ) {
    exit;
}

my ($funder, $funding_id);
if ( ref $in->{project} eq 'ARRAY' ) {
    foreach my $x ( @{$in->{project}} ) {
        push @$funder, {
            basic_information => {
                name => $x->{funding}{name},
            },
        };
        push(@$funding_id, $x->{funding}{number}) if $x->{funding}{number};
    }
}
elsif ( $in->{project}{funding}{name} ) {
    $funder = $in->{project}{funding}{name};
    $funding_id = $in->{project}{funding}{number}.'' if $in->{project}{funding}{number};
}

my %out = (
    inhaltliche_angaben => {
        titel                  => $in->{title}{name}, # mandatory
        beschreibung           => $in->{description} =~ s/\R\R.*//rs, # mandatory, only first paragraph
        größe                  => sprintf('%d Dokumente, %d Tokens', $in->{numbers}{documents}, $in->{numbers}{tokens}), # mandatory
        lizenz                 => $in->{availability}{name}, # mandatory
        'lizenz-url'           => $in->{availability}{url}, # mandatory
        modalität              => $in->{modality}, # mandatory
        sprache                => [ map { $_->{iso} } @{$in->{languages}} ], # optional
        datentyp               => [ qw(collection text) ], # mandatory | vocabulary
        erstellungsdatum       => undef, # not yet in DTA
        veröffentlichungsdatum => undef, # not yet in DTA
        abgedeckter_zeitraum   => sprintf('%s-%s', $in->{timeCoverage}{start}, $in->{timeCoverage}{end}), # optional
        volltext_verfügbar     => 'available', # mandatory | vocabulary
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
        kollektionstyp         => undef, # optional
        genre                  => undef, # [ map { $_->{sub} ? sprintf('%s::%s', $_->{main}, $_->{sub}) : $_->{main} } @{$in->{genre}} ], # optional
        fachliche_zuordnung    => [ @{$in->{disciplines}} ], # optional
        schlagworte            => [ grep { $_ ne 'Text+' } @{$in->{keywords}} ], # optional
    },
    technische_angaben => {
        pid                      => $in->{urls}{landingPage}, # required
        zugang                   => $in->{urls}{searchPage},  # required
        hierarchie               => undef, # optional | see relations_internal_is_part_of or relations_internal_contains
        bezug                    => undef, # optional
        dateien_datenströme      => undef, # optional | ggf. Livelink zu Heimatorganisation
        technische_dokumentation => undef, # optional
    },
    organisatorische_angaben => {
        datenverantwortliche_person => { # optional
            basic_information => {
                lastname => $in->{association}{editors}[0]{name}
            },
        },
        datenverantwortliche_institution => { # optional
            basic_information => {
                name => $in->{association}{institution}{name}
            },
        },
        ansprechperson => { # optional
            basic_information => {
                lastname => $in->{association}{editors}[0]{email}
            },
        },
        förderer     => $funder, # optional
        förderer_id  => $funding_id, # optional
        projekttitel => (ref $in->{project} eq 'ARRAY' ? [ map { $_->{name} } @{$in->{project}} ]
                                                       : $in->{project}{name}),
    },
);

say encode_json(\%out);
__END__
