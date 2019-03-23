use strict;
use lib('.');
use Token;

my $parser = new Token("testfile.json","outputfile.json");
my $token = -1;
while ($token != 6) {
  $token = $parser->getnext(1);
  printf "%d ", $token;
}
