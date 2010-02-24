use strict;
use warnings;
use Test::More;
use Test::Deep;

plan tests => 19;

use lib qw( t/lib );
use_ok('Sys::Detect::Virtualization::dummy_linux');

my $d = Sys::Detect::Virtualization::dummy_linux->new();
#$d->{verbose} = 1;

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
	openvz    => [ ],
);

my %expected_dmidecode = (
	kvm       => [
		Sys::Detect::Virtualization::VIRT_QEMU(),
		Sys::Detect::Virtualization::VIRT_KVM()
	],
	vmware    => [ Sys::Detect::Virtualization::VIRT_VMWARE()    ],
	virtualpc => [ Sys::Detect::Virtualization::VIRT_VIRTUALPC() ],
	openvz    => [ ],
);

my %expected_lsmod = (
	kvm       => [
		Sys::Detect::Virtualization::VIRT_KVM(),
		Sys::Detect::Virtualization::VIRT_LGUEST(),
		Sys::Detect::Virtualization::VIRT_KVM(),
		Sys::Detect::Virtualization::VIRT_LGUEST(),
	],
	vmware    => [
		Sys::Detect::Virtualization::VIRT_VMWARE(),
		Sys::Detect::Virtualization::VIRT_VMWARE(),
	],
	virtualpc => [ ],
	openvz    => [ ],
);

my %expected_mtab = (
	kvm => [ ],
	vmware => [ ],
	virtualpc => [ ],
	openvz    => [
		Sys::Detect::Virtualization::VIRT_OPENVZ(),
	],
);

{
	local $ENV{PATH} = 't/bin';
	foreach my $virt (qw( kvm vmware virtualpc openvz)) {
		local $ENV{FAKE_DATA} = "t/data/linux/$virt";

		my $got = $d->detect_dmesg();
		cmp_deeply(
			$got,
			$expected_dmesg{$virt},
			"detect_dmesg() against $virt test data") or diag explain $got;

		$got = $d->detect_dmidecode({ ignore_root_check => 1 });
		cmp_deeply(
			$got,
			$expected_dmidecode{$virt},
			"detect_dmidecode() against $virt test data") or diag explain $got;

		$got = $d->detect_modules();
		cmp_deeply(
			$got,
			$expected_lsmod{$virt},
			"detect_modules() against $virt test data") or diag explain $got;

		$got = $d->detect_mtab();
		cmp_deeply(
			$got,
			$expected_mtab{$virt},
			"detect_mtab() against $virt test data") or diag explain $got;

	}
}
