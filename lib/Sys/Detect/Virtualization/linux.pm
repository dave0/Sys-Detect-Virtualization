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
		  ],
	);

}

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

1;
