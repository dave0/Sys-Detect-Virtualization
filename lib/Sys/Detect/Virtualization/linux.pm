package Sys::Detect::Virtualization::linux;
use warnings;
use strict;

use base qw( Sys::Detect::Virtualization );

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
		'dmesg',
		[
			# VMWare
			qr/vmxnet virtual NIC/i       => 'VMWare',
			qr/vmware virtual ide cdrom/i => 'VMWare',

			# Qemu / KVM
			qr/qemu virtual cpu/i => 'Qemu or KVM',

			# Microsoft virtual PC
			qr/Virtual HD, ATA DISK drive/i => 'VirtualPC',
			qr/Virtual CD, ATAPI CD/i       => 'VirtualPC',

			# Xen
			qr/Xen virtual console/ => 'Xen',

			# Newer kernels are enlightened...
			qr/booting paravirtualized kernel on kvm/i => 'KVM',
			qr/booting paravirtualized kernel on lguest/i => 'lguest',
			qr/booting paravirtualized kernel on vmi/i => 'VMWare',
			qr/booting paravirtualized kernel on xen/i => 'Xen',
		  ],
	);

}

=item detect_dmidecode ( )

Check the output of the 'dmidecode' command for telltales.

=cut

sub detect_dmidecode
{
	my ($self) = @_;

	if( $> != 0 ) {
		die "precondition not met: root required for this detector";
	}

	return $self->_check_command_output(
		'dmidecode 2> /dev/null',
		[
			# VMWare
			qr/Manufacturer:\s+VMWare, Inc/ => 'VMWare',
			qr/Product Name:\s+VMWare/      => 'VMWare',

			# Qemu / KVM
			qr/Vendor: QEMU/ => 'Qemu or KVM',
		],
	);
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
			qr/vmware virtual/ => 'VMWare',

			# VirtualPC
			qr/Virtual [HC]D/i => 'VirtualPC',

			# Qemu / KVM
			qr/QEMU (?:HARDDISK|DVD-ROM)/i => 'Qemu or KVM',
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
			qr{^/dev/hdv1 } => 'vserver',
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
			qr/Vendor: VMware   Model: Virtual disk/ => 'VMWare',
		]
	);
}

=item detect_paths ( )

Check for particular paths that only exist under virtualization.

=cut

sub detect_paths
{
	my ($self) = @_;
	$self->_check_path_exists([
		'/dev/vzfs' => 'Virtuozzo',
		'/dev/vzctl' => 'Virtuozzo or OpenVZ Host',
		'/proc/vz'  => 'Virtuozzo Guest or Host',
		'/proc/sys/xen/independent_wallclock' => 'Xen',
	]);
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
