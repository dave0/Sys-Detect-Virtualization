package Sys::Detect::Virtualization;

use warnings;
use strict;

=head1 NAME

Sys::Detect::Virtualization - Detect if a UNIX system is running as a virtual machine

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';


=head1 SYNOPSIS

    use Sys::Detect::Virtualization;

    my $detector = eval { Sys::Detect::Virtualization->new() };
    if( $@ ) {
	print "Detector may not be supported for your platform.  Error was: $@\n";
    }

    my @found = $detector->detect();
    if( @found ) {
	print "Possible virtualized system.  May be running under:\n";
	print "\t$_\n" for @found;
    }

=head1 DESCRIPTION

This module attempts to detect whether or not a system is running as a guest
under virtualization, using various heuristics.

=head1 METHODS

=head2 Class Methods

=over 4

=item new ( )

Construct a new detector object.  On success, returns the object.  On failure, dies.

This constructor will fail if the system is not running a supported OS.
Currently, only Linux is supported.

=back

=cut

sub new
{
	my ($class, @extra_args) = @_;

	die q{Perl doesn't know what OS you're on!} unless $^O;
	my $submodule = join('::', __PACKAGE__, lc $^O);

	eval "use $submodule";
	my $local_err = $@;
	if( $local_err =~ m{Can't locate Sys/Detect/Virtualization/.*?\.pm} ) {
		die "Virtualization detection not supported for '$^O' platform";
	} elsif( $local_err ) {
		die "Constructor failure: $local_err";
	}

	return $submodule->new(@extra_args);
}

=head2 Instance Methods

=over 4

=item detect ( )

Runs detection heuristics.  Returns a list of possible virtualization systems,
or an empty list if none were detected.

Note that the failure to detect does NOT mean the system is not virtualized --
it simply means we couldn't detect it.

=back

=cut

sub detect
{
}

=head1 AUTHOR

Dave O'Neill, <dmo@dmo.ca>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-detect-virtualization at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Detect-Virtualization>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Detect::Virtualization


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-Detect-Virtualization>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-Detect-Virtualization>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-Detect-Virtualization>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-Detect-Virtualization/>

=item * The author's blog

L<http://www.dmo.ca/blog/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Dave O'Neill.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Sys::Detect::Virtualization
