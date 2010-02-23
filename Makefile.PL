use inc::Module::Install;

name     'Sys-Detect-Virtualization';
all_from 'lib/Sys/Detect/Virtualization.pm';
author   q{Dave O'Neill <dmo@roaringpenguin.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

