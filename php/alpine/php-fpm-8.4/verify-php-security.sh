#!/bin/sh
# CVE-2026-109618 / CVE-2026-109619: validate CLI and the web runtime.
set -eu
php -n -r 'if (PHP_MAJOR_VERSION !== 8 || PHP_MINOR_VERSION !== 4 || version_compare(PHP_VERSION, "8.4.27", "<")) { fwrite(STDERR, "PHP 8.4.27 or later in the 8.4 branch is required; got " . PHP_VERSION . "\n"); exit(1); }'
fpm_version="$(php-fpm -n -v | sed -n 's/^PHP \([0-9][0-9.]*\).*$/\1/p' | head -n 1)"
php -n -r 'if (!preg_match("/^8\\.4\\.[0-9]+$/", $argv[1]) || version_compare($argv[1], "8.4.27", "<")) { fwrite(STDERR, "PHP-FPM 8.4.27 or later in the 8.4 branch is required; got {$argv[1]}\n"); exit(1); } echo "Verified PHP CLI and FPM security minimum (8.4.27).\n";' "$fpm_version"
