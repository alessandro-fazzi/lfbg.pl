package Lfbg;
use FindBin qw($Bin);
use File::Find;
use Data::Dumper;
use POSIX ;
use Net::SMTP_auth;
use HTML::Entities;
use HTML::Strip;

our $abs_path = $Bin;
do "$abs_path/lfbg.conf"; #include user configurations


sub get_list {
  open FH, $_[0] or die $!;
  @fh = <FH>;
  chomp @fh;
  local $"="|";
  my $list = qr/@fh/ix;
  return $list;
}

sub get_paths {

  $scanpath =~ s/ +/,/; #if user separated paths with spaces convert to commas
  my @pathlist = split(/,/, $scanpath); #get a list of paths
  my @globbedpaths = map { glob($_) } @pathlist; #if globbing star used, expand it
  my @scanpath = grep { /^.+$/ and -d } @globbedpaths; #delete non-folders and empty, just to sanitize

  return @scanpath;
}

sub process {
  local ($model, $verbose) = @_;
  local @output = ();
  local $includelist = get_list("$abs_path/models/$model/include.list");
  local $regexlist = get_list("$abs_path/models/$model/regex.list");
  local $excludelist = get_list("$abs_path/models/$model/exclude.list");

  {
  my @scanpath = get_paths;
  if ($model eq 'filenames') { Lfbg::search(@scanpath); }
  elsif ($model eq 'malicious-snippets') { Lfbg::search_and_scan(@scanpath); }
  elsif ($model eq 'wp-pharma-hack') { Lfbg::search_and_scan(@scanpath); }
  else { Lfbg::search_and_scan(@scanpath); }

  print @output." matches found for --> $model <-- search model.";
  }

  return @output;
}

sub search {
  my @scanpath = @_;
  find({ wanted => \&match, preprocess => \&mysort }, @scanpath);
}

sub search_and_scan{
  my @scanpath = @_;
  find({ wanted => \&match_content, preprocess => \&mysort }, @scanpath);
}

sub match{

  $File::Find::name =~ m/$excludelist/ and return;
  -f and /$includelist/ and
      $output = "$File::Find::dir/<strong>$_</strong>\t matched $&" and
      collect($output);
}

sub match_content{
  
  $File::Find::name =~ m/$excludelist/ and return;
  -f and /$includelist/ or return;

  open (FH, $_);
  my @lines = <FH>;
  my @local_output = ();

  my $linenu = 0;
  for my $line (@lines){
    ++$linenu;
    
    $line =~ s/^\s+//;
    $line =~ /$regexlist/ or next;
    
    my $hs = HTML::Strip->new();
    my $clean_line = $hs->parse( $line );
    $hs->eof;
    my $clean_match = $hs->parse( $& );
    $hs->eof;

    push @local_output, "\t<span class=\"singlematch\"><blockquote>On line $linenu ->" . $clean_match . "</span><br />\n\t\t
    <blockquote><pre>".$clean_line."</pre></blockquote></blockquote>";
  }
  
  $output = "Searching in file <strong>$File::Find::name</strong>... ".@local_output." matches:\n<br />
  <div class=\"grey\">@local_output</div>" and
  collect($output) unless @local_output eq 0;

}

sub mysort{
  sort @_;
}

sub collect{
  my $input = $_[0];
  if ($verbose){
    my $hs = HTML::Strip->new();
    my $clean_input = $hs->parse( $input );
    $clean_input =~ s/\s+//;
    print $clean_input;
  }
  push @output, "<div class=\"section\">$input</div><br />";

}

sub mailout{
  my $model = shift;
  my $now = localtime;

  $text = <<EOT
  <html>  <head><title>WP passive sec report - $model</title>
  <style type="text/css">.section{padding:5px;font-size:small;background:#ccc;}.grey{background:#eee;padding:5px;}
  </style></head><h2>Report for scan model $model</h2>@_</html>
EOT
;

  $smtp = Net::SMTP_auth->new( $smtp_server,
                    Hello => $helo,
                    Timeout => 60,
                    Debug => $smtp_debug
                    );
  $smtp->auth( 'PLAIN', $user , $password ) or die "Could not authenticate $!";
  $smtp->mail($from);
  $smtp->to($to);
  $smtp->cc($cc);
  $smtp->data;
  $smtp->datasend("MIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8 \n");
  $smtp->datasend("Date:$now\n");
  $smtp->datasend("From: $from\n");
  $smtp->datasend("To: $to\n");
  $smtp->datasend("Cc: $cc\n");
  $smtp->datasend("Subject: $subj\n");
  $smtp->datasend("\n");
  $smtp->datasend("$text");
  $smtp->dataend;
  $smtp->quit;

}

1
