#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Detect::Virtualization' ) || print "Bail out!
";
}

diag( "Testing Sys::Detect::Virtualization $Sys::Detect::Virtualization::VERSION, Perl $], $^X" );
