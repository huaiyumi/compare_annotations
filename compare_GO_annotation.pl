#! /usr/local/bin/perl

#####
#####
##
##  This script is to compare two files with GO annotations.
##   Inputs:
##     -p  predicted annotations
##     -r  reference annotations, e.g., all GO experimental annotations
##     -g  GO parent terms look up file.
##
#####
#####

# get command-line arguments
use Getopt::Std;
getopts('o:i:p:r:g:e:vVh') || &usage();
&usage() if ($opt_h);         # -h for help
$outFile = $opt_o if ($opt_o);    # -o for (o)utput file (redirect STDOUT)
$inFile = $opt_i if ($opt_i);     # -i for (i)Input file (redirect STDIN)
$predicted = $opt_p if ($opt_p);  # -p for the predicted annotation file
$reference = $opt_r if ($opt_r);  # -c for the reference annotations to compare
$go_parents = $opt_g if ($opt_g);   # -g for the go parents file
$errFile = $opt_e if ($opt_e);    # -e for (e)rror file (redirect STDERR)
$verbose = 1 if ($opt_v);         # -v for (v)erbose (debug info to STDERR)
$verbose = 2 if ($opt_V);         # -V for (V)ery verbose (debug info STDERR)


###################################
# Working on GO parents
###################################

my %go_parents;
#my %go_children;
open (GP, $go_parents);
while (my $line=<GP>){
    chomp $line;
    my ($child, $parent, $relation, $aspect)=split(/\t/, $line);
    $child=~s/.+\((GO\:\d+)\)$/$1/;
    $parent=~s/.+\((GO\:\d+)\)$/$1/;
    $go_parents{$child}{$parent}=1;
}
close (GP);

####################################
# Working on annotation files
####################################

my %predicted = &parse_annotations($predicted);  # predicted annotations
my %reference = &parse_annotations($reference);  # the reference, e.g., exp annotations.


########################################
# Compare
########################################

foreach my $id (keys %predicted){
    foreach my $go_p (keys %{$predicted{$id}}){
        if (exists $reference{$id}){
            my %hash;
            foreach my $go_r (keys %{$reference{$id}}){
                if ($go_p eq $go_r){
                    $hash{'direct'}{$go_r}=1;   # when the go terms in the predicted and reference are identical.
                }elsif (exists $go_parents{$go_p}{$go_r}){
                    $hash{'related'}{$go_r}=1;  # when the go term in the predicted is more specific to the one in the reference.
                }elsif (exists $go_parents{$go_r}{$go_p}){
                    $hash{'true'}{$go_r}=1;     # when the go term in the predicted is more general to the one in the reference.
                }
            }
            my $map;
            if (exists $hash{'direct'}){
               $map = &map(\%hash, 'direct');
            }elsif (exists $hash{'true'}){
                $map = &map(\%hash, 'true');
            }elsif (exists $hash{'related'}){
                $map = &map(\%hash, 'related');
            }else{
                $map = "unrelated";   # The go terms in the reference are not related to the ones in the predicted.
            }
            print "$id\t$go_p\t$map\n"
        }else{
            print "$id\t$go_p\t\tno map\n";   # There is no go annotation in the reference.
        }
    }
}


####################
# Subroutines
####################

sub parse_annotations{
    my $file = shift @_;
    my %hash;
    open (FH, $file);
    while (my $line=<FH>){
        chomp $line;
        my ($id, $go) = split(/\t/, $line);$
        hash{$id}{$go}=1;
    }
    close (file);
    return %hash;
}

sub map{
    my ($href, $foo) = @_;
    
    my @a = keys %{$href->{$foo}};
    my $a = join("\;", @a);
    my $b = "$a\t$foo";
    return $b;
}
