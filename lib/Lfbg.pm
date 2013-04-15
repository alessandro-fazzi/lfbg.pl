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
  $includelist = Lfbg::get_list("$abs_path/models/$model/include.list");

  -f and /$includelist/ and
    print "$File::Find::dir/" . `tput rev` . "$_" . `tput rmso` . " matched $&" if $verbose;

}

sub match_content{
  $includelist = get_list("$abs_path/models/$model/include.list");
  $regexlist = get_list("$abs_path/models/$model/regex.list");
  
  -f and /$includelist/ or return;
  open (FH, $_);
  my @lines = <FH>;

  my @output = ();
  my $linenu = 0;
  for my $line (@lines){
    ++$linenu;
    
    $line =~ s/^\s+//;
    $line =~ /$regexlist/ or next;
    
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse( $line );
    $hs->eof;
    my $clean_match = $hs->parse( $& );
    $hs->eof;

    push @local_output, "\t<span class=\"singlematch\"><blockquote>On line $linenu ->" . $clean_match . "</span><br />\n\t\t
    <blockquote><pre>".$clean_text."</pre></blockquote></blockquote>";
    
    
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

sub mailout{

  $to = 'alessandro.fazzi@welaika.com';
  $from = 'wpsecurity@welaika.com';
  $subj = 'WP passive security report';
  $user = 'www@welaika.com';
  $password = "U+o?V'xX";
  
  $text = <<EOT
  <html>  <head><title>WP passive sec report</title>
  <style type="text/css">.section{padding:5px;font-size:small;background:#ccc;}.grey{background:#eee;padding:5px;}
  </style></head>@_</html>
EOT
;

  $smtp = Net::SMTP->new( "mail.welaika.com",
                    Hello => 'test.welaika.com',
                    Timeout => 60,
                    Auth => [ $user, $password ],
                    Debug => 0
                    );

  $smtp->mail($from);
  $smtp->recipient($to);
  $smtp->data;
  $smtp->datasend("MIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8 \n");
  $smtp->datasend("From: $from\n");
  $smtp->datasend("To: $to\n");
  #$smtp->datasend("Cc: matteo.giaccone\@welaika.com\n");
  $smtp->datasend("Subject: $subj\n");
  $smtp->datasend("\n");
  $smtp->datasend("$text");
  $smtp->dataend;
  $smtp->quit;

}

1
