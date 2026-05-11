#! /usr/local/bin/perl

#####
#####
##
##  findParentCats_OBO.pl -- This script takes the GO file in OBO format 
##                and find all parent categories for each category.  
##      -i  for (i)nput gene_ontology.obo.txt
##      -o  for (o)utput file.  The format is one parent per line.  
##          Format:  Child cat<TAB>Parent cat<TAB>relation<TAB>ontology
##          Example:
##
#####
#####

# get command-line arguments
use Getopt::Std;
getopts('o:i:e:vVh') || &usage();
&usage() if ($opt_h);         # -h for help
$outFile = $opt_o if ($opt_o);    # -o for (o)utput file 
$inFile = $opt_i if ($opt_i);     # -i for (i)Input original GO ontology file
$errFile = $opt_e if ($opt_e);    # -e for (e)rror file (redirect STDERR)
$verbose = 1 if ($opt_v);         # -v for (v)erbose (debug info to STDERR)
$verbose = 2 if ($opt_V);         # -V for (V)ery verbose (debug info STDERR)

###
### My script
###


my %GOterms;
my %GOparents;
my %GOtype;
my %obsolete;
open (FH, $inFile);
local $/="\n\n";
my $header=<FH>;

while (my $term=<FH>){
    chomp $line;
    
    my $id;
    my $name;
    my $namespace;
    my $obsolete;
    my @isa;
    my @relation;
    
    my @lines=split(/\n/, $term);
    foreach my $line (@lines){
        my ($type, $entry)=split(/\:\s/, $line);
        if ($type eq 'id'){
            $id=$entry;
        }elsif ($type eq 'name'){
            $name=$entry;
        }elsif ($type eq 'namespace'){
            $namespace=$entry;
        }elsif ($type =~/is\_a/){
            push (@isa, $entry);
            # print "$entry\n";
        }elsif ($type eq 'relationship'){
            push (@relation, $entry);
            #print "$entry\n";
        }elsif ($type eq 'is_obsolete'){
            $obsolete++ if ($entry=~m/true/);
        }
    }
    
    
    
    
    $GOterms{$id}=$name;
    $GOtype{$id}=$namespace;
    
    if (@isa){
        
        foreach my $item (@isa){
            my ($parentId, $parentName)=split(/\s\!\s/, $item);
            #     print "$name\($id\)\t$parentName\($parentId\)\tis_a\t$namespace\n";
            $GOparents{$id}{$parentId}='is_a';
        }
    }
    
    if (@relation){
        foreach my $item (@relation){
            my ($relation, $parentId, $parentName)=$item=~m/(\S+)\s(GO\:\d+)\s\!\s(.+)/;
            #    print "$name\($id\)\t$parentName\($parentId\)\t$relation\t$namespace\n";
            next unless ($relation eq 'part_of');
            $GOparents{$id}{$parentId}=$relation;
        }
        
    }
    
    if ($obsolete){
        $obsolete{$id}=1;
    }
    
}
close (FH);

# Create all go parent hash

my %go_hierarchy;  # A hash of each GO to all its parents.

foreach my $go (keys %GOterms){

    my $c_go = $go;
    my %parent_go;
    if (defined $GOparents{$c_go}){
        my @array = keys %{$GOparents{$c_go}};
        my @children = @array;
        while (@children){
            my @parents;
            foreach my $child (@children){
                $parent_go{$child}=1;
                if (defined $GOparents{$child}){
                    my @a = keys %{$GOparents{$child}};
                    push (@parents, @a);
                        
                }
            }
            @children = @parents;
        }
    }
    foreach my $key (keys %parent_go){
        next unless (defined $GOterms{$key});
        $go_hierarchy{$go}{$key}=1;
    }
}

foreach my $id (keys %GOterms){
    my $name=$GOterms{$id};
    my $namespace=$GOtype{$id};
    if (defined ($go_hierarchy{$id})){
        
        foreach my $key (keys %{$go_hierarchy{$id}}){
            my $relation=$GOparents{$id}{$key};
            my $parentName=$GOterms{$key};
            print "$name\($id\)\t$parentName\($key\)\t$relation\t$namespace\n";
            
        }
        
    }elsif (defined ($obsolete{$id})){
        
        my $parent="obsolete";
        # print "$name\($id\)\t$parent\t$namespace\n";
    }else{
        
        #print "$id\n";
    }
}


sub usage {
    my $error = shift;

    print "Error: $error\n\n" if ($error);

    print <<__EOT;

findGOparents.pl - a program to find parent categories for each GO category.
    The input file is the original GO ontology file.
      -i  for (i)nput GO ontology (original file)
      -o  for (o)utput file.  The format is one parent per line.  
          Example:
           arabinose porter(GO:0015612)    carrier(GO:0005386)
           arabinose porter(GO:0015612)    enzyme(GO:0003824)
           arabinose porter(GO:0015612)    hydrolase(GO:0016787)
Usage:
findGOparents.pl -i -o 

Where args are:
\t-h for help (this message)
\t-i (i)nput GO file (the orginal file, not the tree file)
\t-o (o)utput file (
\t-e (e)rror file (redirect STDERR)
\t-v (v)erbose (debug info to STDERR)
\t-V (V)ery verbose (debug info to STDERR)

__EOT

exit(-1);
}












