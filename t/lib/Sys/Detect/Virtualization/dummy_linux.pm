package Sys::Detect::Virtualization::dummy_linux;
use Sys::Detect::Virtualization::linux;
use base qw( Sys::Detect::Virtualization::linux );

# Dummy class for testing

sub get_detectors
{
	return Sys::Detect::Virtualization::linux->get_detectors();
}

1;
