package Inline::Filters;
use strict;
use Config;
$Inline::Filters::VERSION = "0.10";

#============================================================================
# Object Interface
#============================================================================
sub new {
    my $class = shift;
    return bless { filter => shift, coderef => shift }, $class;
}

sub filter {
    my ($self, $o, $code) = @_;
    return $self->{coderef}->($o, $code);
}

#============================================================================
# Strip POD
#============================================================================
sub Strip_POD {
    my $ilsm = shift;
    my $code = shift;
    $code =~ s/^=\w+[^\n]*\n\n(.*?)(^=cut\n\n|\Z)//gsm;
    return $code;
}

#============================================================================
# Strip comments in various languages
#============================================================================
sub skip_quoted {
    my ($text, $index, $closer) = @_;
    for (my $i=$index+1; $i<length $text; $i++) {
        my $p = substr($text, $i-1, 1);
        my $c = substr($text, $i, length($closer));
        return $i if ($c eq $closer and ($p ne '\\' or length($closer)>1));
    }
    return $index; # must not have been a string
}

sub strip_comments {
    my ($txt, $opn, $cls, @quotes) = @_;
    my $i=-1;
    while (++$i < length $txt) {
	my $closer;
        if (scalar grep{my$r=substr($txt,$i,length($_))eq$_;$closer=$_ if$r;$r} 
            @quotes) {
	    $i = skip_quoted($txt, $i, $closer);
	    next;
        }
        if (substr($txt, $i, length($opn)) eq $opn) {
	    my $e = index($txt, $cls, $i) + length($cls);
	    substr($txt, $i, $e-$i, " ");
	    $i--;
	    next;
        }
    }
    return $txt;
}

# Note: strips both C and C++ comments because so many compilers accept
# both styles for C programs. Perhaps a --strict parameter?
sub Strip_C_Comments {
    my $ilsm = shift;
    my $code = shift;
    $code = strip_comments($code, '//', "\n", '"');
    $code = strip_comments($code, '/*', '*/', '"');
    return $code;
}

sub Strip_CPP_Comments {
    my $ilsm = shift;
    my $code = shift;
    $code = strip_comments($code, '//', "\n", '"');
    $code = strip_comments($code, '/*', '*/', '"');
    return $code;
}

sub Strip_Python_Comments {
    my $ilsm = shift;
    my $code = shift;
    $code = strip_comments($code, '#', "\n", '"', '"""', '\'');
    return $code;
}

sub Strip_TCL_Comments {
    my $ilsm = shift;
    my $code = shift;

    return $code;
}

#============================================================================
# Preprocess C and C++
#============================================================================
sub Preprocess_C {
    my $ilsm = shift;
    my $code = shift;
    my $tmpfile = $ilsm->{build_dir} . "/Filters.c";
    my $cpp = $ilsm->{ILSM}{MAKEFILE}{CC} || $Config{cc}
      . " $Config{ccflags} -I$Config{archlibexp}/CORE"
      . " @{$ilsm->{ILSM}{MAKEFILE}{INC}||[]} -E ";
    $ilsm->mkpath($ilsm->{build_dir});
    open CSRC, ">$tmpfile" or die $!;
    print CSRC $code;
    close CSRC;
    open PROCESSED, "$cpp $tmpfile |" or die $!;
    $code = join'', <PROCESSED>;
    close PROCESSED;
    unlink $tmpfile;
    return $code;
}

sub Preprocess_CPP {
    my $ilsm = shift;
    my $code = shift;
    my $cpp = $ilsm->{ILSM}{MAKEFILE}{CC} 
      . " $Config{ccflags} -I$Config{archlibexp}/CORE"
      . " @{$ilsm->{ILSM}{MAKEFILE}{INC}||[]} -E ";
    my $tmpfile = $ilsm->{build_dir} . "/Filters.cpp";
    $ilsm->mkpath($ilsm->{build_dir});
    open CSRC, ">$tmpfile" or die $!;
    print CSRC $code;
    close CSRC;
    open PROCESSED, "$cpp $tmpfile |" or die $!;
    $code = join'', <PROCESSED>;
    close PROCESSED;
    unlink $tmpfile;
    return $code;
}

#============================================================================
# Returns a list of key, value pairs; a filter and its code reference.
#============================================================================
my %filters = 
  (
   ALL => [
	   Strip_POD => \&Strip_POD,
	  ],
   C => [
	 Strip_Comments => \&Strip_C_Comments,
	 Preprocess => \&Preprocess_C,
	],
   CPP => [
	   Strip_Comments => \&Strip_CPP_Comments,
	   Preprocess => \&Preprocess_CPP,
	  ],
   JAVA => [
	    Strip_Comments => \&Strip_CPP_Comments,
	   ],
  );
sub get_filters {
    my $language = shift;
    my ($all, $lang) = @filters{ALL => $language};
    $lang ||= [];
    return (@$all, @$lang);
}

1;
