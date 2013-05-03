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
  local @output = ();
  {
  if ($model eq 'filenames') { Lfbg::search($model, $verbose); }
  elsif ($model eq 'malicious-snippets') { Lfbg::search_and_scan($model, $verbose); }
  elsif ($model eq 'wp-pharma-hack') { Lfbg::search_and_scan($model, $verbose); }

  print @output." matches found for --> $model <-- search model.";
  }

  return @output;
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
  -f and /$includelist/ and
      $output = "$File::Find::dir/<strong>$_</strong>\t matched $&" and
      collect($output);
}

sub match_content{
  $includelist = get_list("$abs_path/models/$model/include.list");
  $regexlist = get_list("$abs_path/models/$model/regex.list");
  
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

  $text = <<EOT
  <html>  <head><title>WP passive sec report - $model</title>
  <style type="text/css">.section{padding:5px;font-size:small;background:#ccc;}.grey{background:#eee;padding:5px;}
  </style></head><h2>Report for scan model $model</h2>@_</html>
EOT
;

  $smtp = Net::SMTP->new( $smtp_server,
                    Hello => $helo,
                    Timeout => 60,
                    Auth => [ $user, $password ],
                    Debug => 1
                    );

  $smtp->mail($from);
  $smtp->recipient($to);
  $smtp->data;
  $smtp->datasend("MIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8 \n");
  $smtp->datasend("From: $from\n");
  $smtp->datasend("To: $to\n");
  $smtp->datasend("Cc: \n");
  $smtp->datasend("Subject: $subj\n");
  $smtp->datasend("\n");
  $smtp->datasend("$text");
  $smtp->dataend;
  $smtp->quit;

}

1
