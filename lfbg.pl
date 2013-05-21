#!/usr/bin/perl -wl -s
use FindBin qw($Bin);
use lib::Lfbg;
use Data::Dumper;


our ($list, $v, $verbose, $mail, $m);
$verbose = 1 if defined($v);
$mail = 1 if defined($m);

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
  Lfbg::mailout($model, @output) if $mail;
}

