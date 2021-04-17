<?php

namespace WP\SSO;

class SecurityChecks {

	function check_security() {
		if ( ! defined( 'ABSPATH' ) ) {
			exit; // Exit if accessed directly.
		}
	}

}
