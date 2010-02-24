package Sys::Detect::Virtualization;

use warnings;
use strict;
use 5.008;

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
	my ($class, $extra_args) = @_;

	die q{Perl doesn't know what OS you're on!} unless $^O;
	my $submodule = join('::', __PACKAGE__, lc $^O);

	eval "use $submodule";
	my $local_err = $@;
	if( $local_err =~ m{Can't locate Sys/Detect/Virtualization/.*?\.pm} ) {
		die "Virtualization detection not supported for '$^O' platform";
	} elsif( $local_err ) {
		die "Constructor failure: $local_err";
	}

	my $self = $submodule->new($extra_args);
	$self->{verbose} = exists $extra_args->{verbose} ? $extra_args->{verbose} : 0;

	return $self;
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
	my ($self) = @_;

	my @detectors = $self->get_detectors();

	my %virt_found;
	for my $name ( @detectors ) {
		print "Running detector $name\n" if $self->{verbose};

		my $found = eval { $self->$name; };
		if( $found ) {
			$virt_found{$found}++;
			print "$name callback detected $found\n" if $self->{verbose};
		} else {
			if( $@ ) {
				warn "Callback $name failed: $@" if $self->{verbose};
			}
			print "$name callback did not detect virtualization\n" if $self->{verbose};
		}
	}

	return keys %virt_found;
}

=head2 Internal Methods

You probably shouldn't ever need to call these

=over 4

=item get_detectors ( )

Returns a list of all detector subroutines for the given instance.

=cut

sub get_detectors
{
	my ($self) = @_;

	my $class = ref $self;

	no strict 'refs';
	return grep { /^detect_/ } keys %{"${class}::"};
}

=item _fh_apply_patterns ( $fh, $patterns )

Check, linewise, the data from $fh against the patterns in $patterns.

$patterns is a listref read pairwise.  The first item of each pair is the
pattern, and the second item of each pair is the name of the virt solution
detected by the pattern.

=cut

sub _fh_apply_patterns
{
	my ($self, $fh, $patterns) = @_;

	while(my $line = <$fh>) {
		for(my $i = 0; $i < scalar @$patterns; $i+=2) {
			my ($pattern, $name) = @{$patterns}[$i, $i+1];
			if( $line =~ /$pattern/ ) {
				return $name;
			}
		}
	}

	return undef;
}

=item _check_command_output ( $command, $patterns )

Check, linewise, the output of $command against the patterns in $patterns.

$patterns is a listref read pairwise.  The first item of each pair is the
pattern, and the second item of each pair is the name of the virt solution
detected by the pattern.

=cut

sub _check_command_output
{
	my($self, $command, $patterns) = @_;

	# TODO: check $ENV{PATH} for $command first, or trust the shell?

	open( my $fh, "$command|") or die $!;
	my $result = $self->_fh_apply_patterns( $fh, $patterns );
	close $fh;

	return $result;
}

=item _check_file_contents ( $fileglob, $patterns )

Check, linewise, the content of each filename in $fileglob against the
patterns in $patterns.

$fileglob is a glob that returns zero or more filenames.

$patterns is a listref read pairwise.  The first item of each pair is the
pattern, and the second item of each pair is the name of the virt solution
detected by the pattern.

=cut

sub _check_file_contents
{
	my ($self, $fileglob, $patterns) = @_;

	# TODO: caller does globbing, passes listref of filenames?
	while( my $filename = glob($fileglob) ) {
		my $fh;
		if( ! open( $fh, "<$filename") ) {
#			warn "skipping $filename: $!";
			next;
		}
		my $result = $self->_fh_apply_patterns( $fh, $patterns );
		close $fh;
		if( $result ) { return $result };
	}
	return undef;
}

=item _check_path_exists ( $paths )

Checks for the existence of each path in $paths.

$paths is a listref read pairwise.  The first item of each pair is the path
name, and the second item of each pair is the name of the virt solution
detected by the existence of that $path.

=cut

sub _check_path_exists
{
	my ($self, $paths) = @_;

	for(my $i = 0; $i < scalar @{$paths}; $i+=2) {
		my ($path, $name) = @{$paths}[$i, $i+1];
		if( -e $path ) {
			return $name;
		}
	}

	return undef;
}

=back

=head1 AUTHOR

Dave O'Neill, <dmo@dmo.ca>

=head1 BUGS

Known issues:

=over 4

=item *

No support for non-Linux platforms.  Feel free to contribute an appropriate
Sys::Detect::Virtualization::foo class for your platform.

=item *

No weighting of tests so that high-confidence checks can be done first.
Patches welcome.

=back

Please report any bugs or feature requests to C<bug-sys-detect-virtualization
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Detect-Virtualization>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.


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

Copyright (C) 2009 Roaring Penguin Software Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Sys::Detect::Virtualization
