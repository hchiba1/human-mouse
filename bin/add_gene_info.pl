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

my @CODING;
my @CODING2;
my @CODING3;
my @NON_CODING;
my @NON_CODING2;
my @TENTATIVE;
my @TENTATIVE2;
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
    if ($human_gene_type eq 'protein-coding' && $gene_type_match eq 'match') {
        if ($symbols_match eq 'match') {
            my $output = join("\t", @f
                              , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                );
            push @CODING, $output;
        } elsif ($symbols_match eq 'mismatch') {
            my $output = join("\t", @f
                              , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                );
            push @CODING2, $output;
        } else {
            my $output = join("\t", @f
                              , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                );
            push @CODING3, $output;
        }
    } elsif ($human_gene_type eq 'biological-region' && $gene_type_match eq 'match') {
        my $output = join("\t", @f
                          , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                          , $human_gene_type, $mouse_gene_type
            );
        push @NON_CODING, $output;
    } elsif ($human_gene_type eq 'ncRNA' && $gene_type_match eq 'match') {
        my $output = join("\t", @f
                          , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                          , $human_gene_type, $mouse_gene_type
            );
        push @NON_CODING2, $output;
    } elsif ($gene_type_match eq 'match') {
        my $output = join("\t", @f
                          , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                          , $human_gene_type, $mouse_gene_type
                          , $gene_type_match
            );
        push @TENTATIVE, $output;
    } else {
        my $output = join("\t", @f
                          , $human_gene_symbol, $mouse_gene_symbol, $symbols_match
                          , $human_gene_type, $mouse_gene_type
                          , $gene_type_match
            );
        push @TENTATIVE2, $output;
    }
}

open(CODING, ">human-mouse.protein-coding.tsv") || die "$!";
print CODING join("\t", "human_gene_id", "mouse_gene_id"
                  , "human_symbol", "mouse_symbol", "symbol_match"
    ), "\n";
if (@CODING) {
    print CODING join("\n", @CODING), "\n";
}
if (@CODING2) {
    print CODING join("\n", @CODING2), "\n";
}
if (@CODING3) {
    print CODING join("\n", @CODING3), "\n";
}
close(CODING);

open(NC, ">human-mouse.non-coding.tsv") || die "$!";
print NC join("\t", "human_gene_id", "mouse_gene_id"
              , "human_symbol", "mouse_symbol", "symbol_match"
              , "human_gene_type", "mouse_gene_type"
    ), "\n";
if (@NON_CODING) {
    print NC join("\n", @NON_CODING), "\n";
}
if (@NON_CODING2) {
    print NC join("\n", @NON_CODING2), "\n";
}
close(NC);

open(TENTATIVE, ">human-mouse.tentative.tsv") || die "$!";
print TENTATIVE join("\t", "human_gene_id", "mouse_gene_id"
               , "human_symbol", "mouse_symbol", "symbol_match"
               , "human_gene_type", "mouse_gene_type"
               , "gene_type_match"
    ), "\n";
if (@TENTATIVE) {
    print TENTATIVE join("\n", @TENTATIVE), "\n";
}
if (@TENTATIVE2) {
    print TENTATIVE join("\n", @TENTATIVE2), "\n";
}
close(TENTATIVE);
