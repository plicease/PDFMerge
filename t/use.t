use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More tests => 3;

use_ok 'PDFMerge';
use_ok 'PDFMerge::Controller';
use_ok 'PDFMerge::Data';
