use strict;
use warnings;
use Test::More;
use Test::Deep;

plan tests => 9;

use lib qw( t/lib );
use_ok('Sys::Detect::Virtualization::dummy_linux');

my $d = Sys::Detect::Virtualization::dummy_linux->new();

isa_ok( $d, 'Sys::Detect::Virtualization::linux');

is_deeply(
	[ sort $d->get_detectors() ],
	[ sort qw( detect_dmesg detect_ide_devices detect_paths detect_scsi_devices detect_modules detect_mtab detect_dmidecode) ],
	'Got expected detectors on Linux');

# Some tests return multiple hits for the same virt engine
my %expected_dmesg = (
	kvm       => [
		Sys::Detect::Virtualization::VIRT_KVM(),
		Sys::Detect::Virtualization::VIRT_QEMU(),
		Sys::Detect::Virtualization::VIRT_KVM(),
	],
	vmware    => [ Sys::Detect::Virtualization::VIRT_VMWARE()    ],
	virtualpc => [
		Sys::Detect::Virtualization::VIRT_VIRTUALPC(),
		Sys::Detect::Virtualization::VIRT_VIRTUALPC()
	],
);

my %expected_dmidecode = (
	kvm       => [
		Sys::Detect::Virtualization::VIRT_QEMU(),
		Sys::Detect::Virtualization::VIRT_KVM()
	],
	vmware    => [ Sys::Detect::Virtualization::VIRT_VMWARE()    ],
	virtualpc => [ Sys::Detect::Virtualization::VIRT_VIRTUALPC() ],
);

{
	local $ENV{PATH} = 't/bin';
	foreach my $virt (qw( kvm vmware virtualpc )) {
		local $ENV{FAKE_DATA} = "t/data/linux/$virt";

		cmp_deeply(
			$d->detect_dmesg(),
			$expected_dmesg{$virt},
			"detect_dmesg() against $virt test data");

		cmp_deeply(
			$d->detect_dmidecode({ ignore_root_check => 1 }),
			$expected_dmidecode{$virt},
			"detect_dmidecode() against $virt test data");

	}
}
