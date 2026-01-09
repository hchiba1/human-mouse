#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: cat human_mouse.tsv | $PROGRAM
";

my %OPT;
getopts('', \%OPT);

-t and die $USAGE;

my %GENE;
open(GENE_INFO, "gene_info") || die "$!";
while (<GENE_INFO>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene_id = $f[1];
    my $symbol = $f[2];
    my $gene_type = $f[9];
    $GENE{symbol}{$gene_id} = $symbol;
    $GENE{type}{$gene_id} = $gene_type;
}
close(GENE_INFO);

print join("\t", "human_gene_id", "mouse_gene_id"
           , "human_symbol", "mouse_symbol", "symbol_match"
           , "human_gene_type", "mouse_gene_type"
           , "gene_type_match"
    ), "\n";
my @OUTPUT;
my @OUTPUT2;
my @OUTPUT3;
my @OUTPUT4;
my @OUTPUT5;
while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    if (@f != 2) {
        die "Input format error at line $.: $_\n";
    }
    
    my $human_gene_id = $f[0];
    my $mouse_gene_id = $f[1];
    my $human_gene_symbol = '';
    my $mouse_gene_symbol = '';
    if ($GENE{symbol}{$human_gene_id}) {
        $human_gene_symbol = $GENE{symbol}{$human_gene_id};
    }
    if ($GENE{symbol}{$mouse_gene_id}) {
        $mouse_gene_symbol = $GENE{symbol}{$mouse_gene_id};
    }
    my $symbols_match = 'mismatch';
    my $mouse_gene_symbol_uc = uc($mouse_gene_symbol);
    if ($human_gene_symbol eq '' && $mouse_gene_symbol eq '') {
        $symbols_match = 'symbols_undefined';
    } elsif ($human_gene_symbol eq '') {
        $symbols_match = 'human_undefined';
    } elsif ($mouse_gene_symbol eq '') {
        $symbols_match = 'mouse_undefined';
    } elsif ($human_gene_symbol eq $mouse_gene_symbol_uc) {
        $symbols_match = 'match';
    } elsif ($human_gene_symbol =~ /$mouse_gene_symbol_uc/) {
        $symbols_match = 'human_extra_suffix';
    } elsif ($mouse_gene_symbol_uc =~ /$human_gene_symbol/) {
        $symbols_match = 'mouse_extra_suffix';
    }

    my $human_gene_type = '';
    my $mouse_gene_type = '';
    if ($GENE{type}{$human_gene_id}) {
        $human_gene_type = $GENE{type}{$human_gene_id};
    }
    if ($GENE{type}{$mouse_gene_id}) {
        $mouse_gene_type = $GENE{type}{$mouse_gene_id};
    }
    my $gene_type_match = 'mismatch';
    if ($human_gene_type ne '' && $human_gene_type eq $mouse_gene_type) {
        $gene_type_match = 'match';
    }
    my $output = join("\t", @f
                      , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                      , $human_gene_type, $mouse_gene_type
                      , $gene_type_match
        );
    if ($human_gene_type eq 'protein-coding' && $gene_type_match eq 'match') {
        push @OUTPUT, $output;
    } elsif ($human_gene_type eq 'biological-region' && $gene_type_match eq 'match') {
        push @OUTPUT2, $output;
    } elsif ($human_gene_type eq 'ncRNA' && $gene_type_match eq 'match') {
        push @OUTPUT3, $output;
    } elsif ($gene_type_match eq 'match') {
        push @OUTPUT4, $output;
    } else {
        push @OUTPUT5, $output;
    }
}

if (@OUTPUT) {
    print join("\n", @OUTPUT), "\n";
}
if (@OUTPUT2) {
    print join("\n", @OUTPUT2), "\n";
}
if (@OUTPUT3) {
    print join("\n", @OUTPUT3), "\n";
}
if (@OUTPUT4) {
    print join("\n", @OUTPUT4), "\n";
}
if (@OUTPUT5) {
    print join("\n", @OUTPUT5), "\n";
}
