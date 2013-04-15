#!/usr/bin/perl -wl -s
use FindBin qw($Bin);
use lib::Lfbg;
use Data::Dumper;


our $list;
our $v;
our $verbose;

@models = <$Bin/models/*>;
for (@models) {
  @model_name=split "/", $_;
  $_=$model_name[-1];
}

if ($list) {
  $models_list = join "\n* ", @models;
  $,="/";
  print "* ".$models_list;
  exit 0;
}
$verbose = 1 if defined($v);

@ARGV or print "No given arguments. Aborting" and exit 255;

our $abs_path = $Bin;
our $mailfile = $abs_path . "/mail.html";


for (@ARGV){
  $_ ~~ @models or printf "Nessun modello di ricerca corrispondente a \"$_\"\n";
  $i = $_;
  push @accepted_args, $i if grep {/$i/} @models;
}

@accepted_args and
  print "Accepted arguments are @accepted_args"
    or print "Any of the argumets were valid. Use -list switch to read accepted ones"
      and exit 255;

for my $model (@accepted_args){
  print "Processing $model";
  my @output = Lfbg::process($model, $verbose);
  @output and Lfbg::mailout(@output) or die "No output to mailout";
}

