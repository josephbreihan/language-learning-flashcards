#!/usr/bin/perl
use utf8;

# cardgen.pl revision 1, 9/22/2007
# Joseph Breihan (josephbreihan on gmail)
#
# usage: cardgen.pl subject-dd-mm-yy.txt
# Reads a word list text file in format:
#
# a word/phrase,this is a definition
#
# This should result in 3 pdf files:
# subject-dd-mm-yy.pdf, subject-dd-mm-yy-fronts.pdf,
# subject-dd-mm-yy-backs.pdf
# (-fronts and -backs are for people without double-sided printers)
#
# Requirements: pdflatex installed, a copy of flashcards.cls from
# http://www.ctan.org/tex-archive/help/Catalogue/entries/flashcards.html
# is in the current directory
#
# Tested against TexLive 2007. 


# Map of accents and special characters to TeX escapes:
# (I've only bothered to add the foreign language ones I use-
# feel free to add your own)

our %Special_Escapes = (
    "Á"	=>	"\\'{A}",	#   capital A, acute accent
    "á"	=>	"\\'{a}",	#   small a, acute accent
    "Â"	=>	"\\^{A}",	#   capital A, circumflex accent
    "â"	=>	"\\^{a}",	#   small a, circumflex accent
    "Æ"	=>	'\\AE',		#   capital AE diphthong (ligature)
    "æ"	=>	'\\ae',		#   small ae diphthong (ligature)
    "À"	=>	"\\`{A}",	#   capital A, grave accent
    "à"	=>	"\\`{a}",	#   small a, grave accent
    "Å"	=>	'\\r{A}',	#   capital A, ring
    "å"	=>	'\\r{a}',	#   small a, ring
    "Ã"	=>	'\\~{A}',	#   capital A, tilde
    "ã"	=>	'\\~{a}',	#   small a, tilde
    "Ä"	=>	'\\"{A}',	#   capital A, dieresis or umlaut mark
    "ä"	=>	'\\"{a}',	#   small a, dieresis or umlaut mark
    "Ç"	=>	'\\c{C}',	#   capital C, cedilla
    "ç"	=>	'\\c{c}',	#   small c, cedilla
    "É"	=>	"\\'{E}",	#   capital E, acute accent
    "é"	=>	"\\'{e}",	#   small e, acute accent
    "Ê"	=>	"\\^{E}",	#   capital E, circumflex accent
    "ê"	=>	"\\^{e}",	#   small e, circumflex accent
    "È"	=>	"\\`{E}",	#   capital E, grave accent
    "è"	=>	"\\`{e}",	#   small e, grave accent
    "Œ"	=>	'\\OE',		#   capital Eth, Icelandic
    "œ"	=>	'\\oe',		#   small eth, Icelandic
    "Ë"	=>	'\\"{E}',	#   capital E, dieresis or umlaut mark
    "ë"	=>	'\\"{e}',	#   small e, dieresis or umlaut mark
    "Í"	=>	"\\'{I}",	#   capital I, acute accent
    "í"	=>	"\\'{i}",	#   small i, acute accent
    "Î"	=>	"\\^{I}",	#   capital I, circumflex accent
    "î"	=>	"\\^{i}",	#   small i, circumflex accent
    "Ì"	=>	"\\`{I}",	#   capital I, grave accent
    "ì"	=>	"\\`{i}",	#   small i, grave accent
    "Ï"	=>	'\\"{I}',	#   capital I, dieresis or umlaut mark
    "ï"	=>	'\\"{i}',	#   small i, dieresis or umlaut mark
    "Ñ"	=>	'\\~{N}',	#   capital N, tilde
    "ñ"	=>	'\\~{n}',	#   small n, tilde
    "Ó"	=>	"\\'{O}",	#   capital O, acute accent
    "ó"	=>	"\\'{o}",	#   small o, acute accent
    "Ô"	=>	"\\^{O}",	#   capital O, circumflex accent
    "ô"	=>	"\\^{o}",	#   small o, circumflex accent
    "Ò"	=>	"\\`{O}",	#   capital O, grave accent
    "ò"	=>	"\\`{o}",	#   small o, grave accent
    "Ø"	=>	"\\O",		#   capital O, slash
    "ø"	=>	"\\o",		#   small o, slash
    "Õ"	=>	"\\~{O}",	#   capital O, tilde
    "õ"	=>	"\\~{o}",	#   small o, tilde
    "Ö"	=>	'\\"{O}',	#   capital O, dieresis or umlaut mark
    "ö"	=>	'\\"{o}',	#   small o, dieresis or umlaut mark
    "ß"	=>	'\\ss',		#   small sharp s, German (sz ligature)
    "Ĺ"	=>	'\\L',		#   capital THORN, Icelandic
    "ĺ"	=>	'\\l',,		#   small thorn, Icelandic
    "Ú"	=>	"\\'{U}",	#   capital U, acute accent
    "ú"	=>	"\\'{u}",	#   small u, acute accent
    "Û"	=>	"\\^{U}",	#   capital U, circumflex accent
    "û"	=>	"\\^{u}",	#   small u, circumflex accent
    "Ù"	=>	"\\`{U}",	#   capital U, grave accent
    "ù"	=>	"\\`{u}",	#   small u, grave accent
    "Ü"	=>	'\\"{U}',	#   capital U, dieresis or umlaut mark
    "ü"	=>	'\\"{u}',	#   small u, dieresis or umlaut mark
    "Ý"	=>	"\\'{Y}",	#   capital Y, acute accent
    "ý"	=>	"\\'{y}",	#   small y, acute accent
    "Ÿ"	=>	'\\"{y}',	#   large y, dieresis or umlaut mark
    "ÿ"	=>	'\\"{y}',	#   small y, dieresis or umlaut mark
);

$ARGV[0] =~ /(.*?)-(.*?)-(.*?)-(.*?)\.txt/;

my $basefile = "$1-$2-$3-$4";

for (my $i=0;$i<3;$i++)
{
   my $outfilename = "$basefile.tex";
   my $side;
   if ($i == 1)
   {
	   $side = "fronts";
	   $outfilename = "$basefile-$side.tex";
   }
   if ($i == 2)
   {
	   $side = "backs";
	   $outfilename = "$basefile-$side.tex";
   }
   open INFILE, '<', $ARGV[0];
   open OUTFILE, '>', $outfilename;
   binmode(INFILE,utf8);
   print OUTFILE "\\documentclass[avery5371,frame";
   if ($side ne "") 
   {
	   print OUTFILE ",$side";
   }
   print OUTFILE "]{flashcards}\n";

   print OUTFILE "\\cardbackstyle[\\Huge]{plain}\n";
   print OUTFILE "\\cardfrontstyle[\\Huge]{headings}\n";
   print OUTFILE "\\cardfrontfoot{$2/$3/$4}\n";
   print OUTFILE "\\begin{document}\n";

   foreach my $line (<INFILE>)
   {
      chomp ($line);
      my @def = split(/,/,$line);

      #function to escape accented characters into latex equivalents
      foreach my $key (keys %Special_Escapes)
      {
         my $esc = $Special_Escapes{$key};
         $def[0] =~ s/$key/$esc/g;
      }

      print OUTFILE "\\begin{flashcard}[$1]{\\textbf{$def[0]}}\n";
      print OUTFILE "$def[1]\n";
      #print OUTFILE "\\textit{$def[1]}\n";
      print OUTFILE "\\end{flashcard}\n";
   }
   print OUTFILE "\\end{document}";

   close(INFILE);
   close(OUTFILE);   

}

system("pdflatex $basefile.tex");
system("pdflatex $basefile-fronts.tex");
system("pdflatex $basefile-backs.tex");

