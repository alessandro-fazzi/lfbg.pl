package Lfbg;
use FindBin qw($Bin);
use File::Find;
use Data::Dumper;
use Net::SMTP;
use HTML::Entities;
use HTML::Strip;
our $abs_path = $Bin;
do "$abs_path/lfbg.conf"; #include user configurations

sub get_list {
  open FH, $_[0] or die $!;
  @fh = <FH>;
  chomp @fh;
  local $"="|";
  my $include = qr/@fh/ix;
  return $include;
}

sub process {
  my ($model, $verbose) = @_;
  {
  if ($model eq 'filenames') { Lfbg::search($model, $verbose); last; }
  if ($model eq 'malicious-snippets') { Lfbg::search_and_scan($model, $verbose); last }
  if ($model eq 'wp-pharma-hack') { Lfbg::search_and_scan($model, $verbose); last }
  $finished = 1;
  }
}

sub search {
  local ($model, $verbose) = @_;
  local $includelist = Lfbg::get_list("$abs_path/models/$model/include.list");
  find({ wanted => \&match, preprocess => \&mysort }, $scanpath);
}

sub search_and_scan{
  local ($model, $verbose) = @_;
  find({ wanted => \&match_content, preprocess => \&mysort }, $scanpath);
}

sub match{
  $includelist = Lfbg::get_list("$abs_path/models/$model/include.list");

  -f and /$includelist/ and
    print "$File::Find::dir/" . `tput rev` . "$_" . `tput rmso` . " matched $&" if $verbose;

}

sub match_content{
  $includelist = Lfbg::get_list("$abs_path/models/$model/include.list");
  $regexlist = Lfbg::get_list("$abs_path/models/$model/regex.list");
  
  -f and /$includelist/ or return;
  open (FH, $_);
  my @lines = <FH>;

  my @output = ();
  my $linenu = 0;
  for my $line (@lines){
    ++$linenu;
    $line =~ s/^\s+//;
    $line =~ /$regexlist/ and push @output, "\t".`tput bold`."On line $linenu -> $&".`tput sgr0`."\n\t\t$line";
  }
  
  if (@output != 0) {
    $verbose and print "Searching in file ".`tput rev`."$File::Find::name".`tput rmso`."... ".@output." matches:\n@output"
            or print @output." matches in $File::Find::name";
  }

}

sub mysort{
  sort @_;
}

sub collect{
  $input = $_[0];
  $verbose and print $input;
  push @output, "<div class=\"section\">$input</div><br />";

}

1
