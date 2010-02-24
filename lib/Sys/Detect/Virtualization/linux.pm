package Sys::Detect::Virtualization::linux;
use warnings;
use strict;

use base qw( Sys::Detect::Virtualization );

use Parse::DMIDecode ();

=head1 NAME

Sys::Detect::Virtualization::linux - Detection of virtualization under a Linux system

=head1 DESCRIPTION

See L<Sys::Detect::Virtualization> for usage information.

=head1 METHODS

=head2 Internal Methods

=over 4

=item new ( )

Constructor.  You should not invoke this directly.  Instead, use L<Sys::Detect::Virtualization>.

=cut

sub new
{
	my ($class) = @_;
	my $self = {};
	bless $self, $class;
	return $self;
}

=item detect_dmesg ( )

Check the output of the 'dmesg' command for telltales.

=cut

sub detect_dmesg
{
	my ($self) = @_;

	return $self->_check_command_output(
		$self->_find_bin('dmesg'),
		[
			# VMWare
			qr/vmxnet virtual NIC/i       => [ $self->VIRT_VMWARE ],
			qr/vmware virtual ide cdrom/i => [ $self->VIRT_VMWARE ],

			# Qemu / KVM
			qr/qemu virtual cpu/i => [ $self->VIRT_KVM, $self->VIRT_QEMU ],

			# Microsoft virtual PC
			qr/Virtual HD, ATA DISK drive/i => [ $self->VIRT_VIRTUALPC ],
			qr/Virtual CD, ATAPI CD/i       => [ $self->VIRT_VIRTUALPC ],

			# Xen
			qr/Xen virtual console/ => [ $self->VIRT_XEN ],

			# Newer kernels are enlightened...
			qr/booting paravirtualized kernel on kvm/i => [ $self->VIRT_KVM ],
			qr/booting paravirtualized kernel on lguest/i => [ $self->VIRT_LGUEST ],
			qr/booting paravirtualized kernel on vmi/i => [ $self->VIRT_VMWARE ],
			qr/booting paravirtualized kernel on xen/i => [ $self->VIRT_XEN ],
		  ],
	);

}

=item detect_dmidecode ( )

Check the output of the 'dmidecode' command for telltales.

=cut

sub detect_dmidecode
{
	my ($self, $args ) = @_;

	if( $> != 0 ) {
		die "precondition not met: root required for this detector" unless($args && $args->{ignore_root_check});
	}

	my $decoder = Parse::DMIDecode->new(
		dmidecode => $self->_find_bin( 'dmidecode' ) || '/usr/sbin/dmidecode',
		nowarnings => 1
	);
	$decoder->probe();

	# First, check BIOS vendor
	# BIOS Information
	#         Vendor: QEMU
	if( $decoder->keyword('bios-vendor') eq 'QEMU' ) {
		return [
			$self->VIRT_QEMU,
			$self->VIRT_KVM,
		];
	}

	# VMWare:
	# System Information
	#         Manufacturer: VMware, Inc.
	if( $decoder->keyword('system-manufacturer') =~ /VMWare/i ) {
		return [ $self->VIRT_VMWARE ];
	}

	# System Information
	#         Manufacturer: Microsoft Corporation
	#         Product Name: Virtual Machine
	if(    $decoder->keyword('system-manufacturer') =~ /microsoft/i
	    && $decoder->keyword('system-product-name') =~ /virtual machine/i ) {
		return [ $self->VIRT_VIRTUALPC ];
	}

	return;
}

=item detect_ide_devices ( )

Check /proc/ide/hd*/model for telltale model information.

=cut

sub detect_ide_devices
{
	my ($self) = @_;

	return $self->_check_file_contents(
		'/proc/ide/hd*/model',
		[
			# VMWare
			qr/vmware virtual/ => [ $self->VIRT_VMWARE ],

			# VirtualPC
			qr/Virtual [HC]D/i => [ $self->VIRT_VIRTUALPC ],

			# Qemu / KVM
			qr/QEMU (?:HARDDISK|DVD-ROM)/i => [
				$self->VIRT_QEMU,
				$self->VIRT_KVM,
			],
		]
	);
}

=item detect_mtab ( )

Check /etc/mtab for telltale devices

=cut

sub detect_mtab
{
	my ($self) = @_;

	return $self->_check_file_contents(
		'/etc/mtab',
		[
			# vserver
			qr{^/dev/hdv1 } => [ $self->VIRT_VSERVER ],
		]
	);
}

=item detect_scsi_devices ( )

Check /proc/scsi/scsi for telltale model/vendor information.

=cut

sub detect_scsi_devices
{
	my ($self) = @_;

	return $self->_check_file_contents(
		'/proc/scsi/scsi',
		[
			# VMWare
			qr/Vendor: VMware   Model: Virtual disk/ => [ $self->VIRT_VMWARE ],
		]
	);
}

=item detect_paths ( )

Check for particular paths that only exist under virtualization.

=cut

sub detect_paths
{
	my ($self) = @_;
	return $self->_check_path_exists([
		'/dev/vzfs'  => [ $self->VIRT_OPENVZ ],
		'/dev/vzctl' => [ $self->VIRT_OPENVZ_HOST ],
		'/proc/vz'   => [ $self->VIRT_OPENVZ ],
		'/proc/sys/xen/independent_wallclock' => [ $self->VIRT_XEN ],
	]);
}

=item detect_modules ( )

Check for telltale guest modules

=cut

sub detect_modules
{
	my ($self) = @_;

	return $self->_check_command_output(
		$self->_find_bin( 'lsmod' ),
		[
			# virtio support exists for kvm and lguest
			qr/^virtio_(?:blk|pci|net|balloon)/ => [ $self->VIRT_KVM, $self->VIRT_LGUEST ],
		]
	);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Roaring Penguin Software Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
