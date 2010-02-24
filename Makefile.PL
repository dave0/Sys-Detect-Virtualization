use inc::Module::Install;

name     'Sys-Detect-Virtualization';
all_from 'lib/Sys/Detect/Virtualization.pm';
author   q{Dave O'Neill <dmo@roaringpenguin.com>};
license  'perl';

requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'POSIX';

test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Test::Exception';

install_script 'script/virtdetect';

auto_install;

WriteAll;

