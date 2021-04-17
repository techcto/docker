<?php
/*
Plugin Name: WP SSO
Plugin URI: https://www.solodev.com/
Description: Single Sign On integration for Oauth2
Version: 1.0
Author: Solodev
Author URI: https://www.solodev.com/
*/

namespace WP\SSO;

if ( is_readable( __DIR__ . '/vendor/autoload.php' ) ) {
    require __DIR__ . '/vendor/autoload.php';
}

use WP_Error;
use WP\SSO\UserNonceHelper;
use WP\SSO\Logger;
use WP\SSO\Security;
use WP\SSO\SignOnUserProvider;
use WP\SSO\UserRequestIdHelper;
use Lcobucci\JWT;
use League\OAuth2\Client\Provider\GenericProvider;
use League\OAuth2\Client\Token\AccessTokenInterface;
use GuzzleHttp\Client;

const BASE_URL = 'wp_SSO';

SecurityChecks::check_security();
WPSSOPlugin::initialize();

class WPSSOPlugin {
	const REDIRECT_URL_ON_ERROR   = '/wp-login.php';
	const WP_CLI_COMMAND_NAME     = 'wp';
	const WP_CLI_EMAIL_ARG        = 'user-email';
	const WP_CLI_CLIENT_ARG      = 'client-id';
	const WP_CLI_FIRST_NAME_ARG   = 'first-name';
	const WP_CLI_LAST_NAME_ARG    = 'last-name';
	const WP_CLI_USER_ROLE_ARG    = 'user-role';
	const REDIRECT_URL_ON_SUCCESS = '/wp-admin/';
	const STATE_ARG        = 'state';

	public static $instance;

	private $login_route  = '/index.php';
	private $login_params = array( 'redirect_uri' => '/' . BASE_URL . '/login' );
	private $sign_on_user_provider;
	private $user_state_helper;

	private $user_nonce_helper;

	public function __construct( $sign_on_user_provider, $user_nonce_helper, $user_state_helper ) {
		$this->sign_on_user_provider  = $sign_on_user_provider;
		$this->user_nonce_helper      = $user_nonce_helper;
		$this->user_state_helper = $user_state_helper;
		$guzzyClient = new \GuzzleHttp\Client([
			'defaults' => [
				\GuzzleHttp\RequestOptions::CONNECT_TIMEOUT => 5,
				\GuzzleHttp\RequestOptions::ALLOW_REDIRECTS => true],
			 \GuzzleHttp\RequestOptions::VERIFY => false,
		]);
		$this->provider = new GenericProvider([
			'clientId'                => ''.getenv('CLIENT_ID').'',    // The client ID assigned to you by the provider
			'clientSecret'            => ''.getenv('CLIENT_SECRET').'',    // The client password assigned to you by the provider
			'redirectUri'             => 'http://'.$_SERVER['SERVER_NAME'].'/wp-json/wp_SSO/login',
			'urlAuthorize'            => 'https://id.solodev.com/oauth2/authorize',
			'urlAccessToken'          => 'https://id.solodev.com/oauth2/access_token',
			'urlResourceOwnerDetails' => ''
		]);
		$this->provider->setHttpClient($guzzyClient);
	}

	public static function initialize( $sign_on_user_provider = null, $user_nonce_helper = null, $user_state_helper = null ) {
		$user_state_helper = $user_state_helper ?? new UserRequestIdHelper();
		$sign_on_user_provider  = $sign_on_user_provider ?? new SignOnUserProvider( $user_state_helper );
		$user_nonce_helper      = $user_nonce_helper ?? new UserNonceHelper();
		self::$instance         = new self( $sign_on_user_provider, $user_nonce_helper, $user_state_helper );

		// <domain_name>/index.php?rest_route=/<BASE_URL>/<endpoint>
		add_action(
			'rest_api_init',
			function () {
				register_rest_route(
					BASE_URL,
					'/login',
					array(
						'methods'             => 'GET',
						'callback'            => array( self::$instance, 'login' ),
						'permission_callback' => array( self::$instance, 'permission_check' ),
					)
				);
				register_rest_route(
					BASE_URL,
					'/is_user_logged_in',
					array(
						'methods'             => 'GET',
						'callback'            => array( self::$instance, 'is_user_logged_in' ),
						'permission_callback' => array( self::$instance, 'permission_check' ),
					)
				);
				register_rest_route(
					BASE_URL,
					'/has_logged',
					array(
						'methods'             => 'POST',
						'callback'            => array( self::$instance, 'has_logged' ),
						'permission_callback' => array( self::$instance, 'permission_check' ),
					)
				);
			}
		);

		if ( defined( 'WP_CLI' ) && \WP_CLI ) {
			\WP_CLI::add_command( self::WP_CLI_COMMAND_NAME, self::$instance );
		}

	}

	public function permission_check( $request ) {
		$referer = $request->get_header( 'referer' );
		if ( null !== $referer && strpos( $referer, 'wp-json' ) !== false ) {
			Logger::log( Logger::WP_JSON_REFERER_ERROR, 'Request coming from wp-json' );
			return new WP_Error( 'bad_request', __( 'Bad request' ), array( 'status' => 400 ) );
		}
		return true;
	}

	public function has_logged( $request ) {
		list( $client_id, $code, $state ) = $this->get_params_from_has_logged_request( $request );
		$response_body                                  = false;
		try {
			if ( $this->is_state_empty( $state ) ) {
				$state_header = self::STATE_ARG;
				Logger::log( Logger::NO_REFERAL_ID_ERROR, "The $state_header http header is empty" );
			}

			if ( is_multisite() ) {
				throw new MultisiteEnabledException();
			}

			if ( ! $this->validate_client_id( $client_id ) ) {
				throw new InvalidInstallNameException( 'Received: ' . $client_id );
			}

			$response_body = $this->user_state_helper->state_matches_logged_state_for_user( $code, $state );

		} catch ( InvalidInstallNameException $e ) {
			Logger::log( Logger::INSTALL_NAME_ERROR, $e->getMessage() );
		} catch ( NoRefererException $e ) {
			Logger::log( Logger::NO_REFERER_ERROR, $e->getMessage() );
		} catch ( MultisiteEnabledException $e ) {
			Logger::log( Logger::MULTISITE_ENABLED_ERROR, $e->getMessage() );
		} catch ( \Exception $e ) {
			Logger::log( Logger::GENERAL_EXCEPTION_ERROR, $e->getMessage() );
		}

		$response = new \WP_REST_Response( $response_body ? 'true' : 'false', 200 );

		return $response;
	}

	public function login( $request ) {
		$time_start = round( microtime( true ) * 1000 );

		try {
			if ( is_multisite() ) {
				throw new MultisiteEnabledException();
			}

			if ( ! is_ssl() && force_ssl_admin() ) {
				return $this->generate_https_redirect( $request->get_query_params() );
			}

			list( $nonce, $code, $client_id, $state ) = $this->get_params_from_login_request( $request );

			if ( $this->is_state_empty( $state ) ) {
				$state_header = self::STATE_ARG;
				Logger::log( Logger::NO_REFERAL_ID_ERROR, "The $state_header http header is empty" );
			}

			//New
			if ($code) {
				$accessToken = $this->provider->getAccessToken('authorization_code', [
					'code' => $code,
				]);
				$token = $this->handleAccessToken($accessToken);
			}
			var_dump($token);die();
			
			//End

			if ( ! $this->validate_client_id( $client_id ) ) {
				throw new InvalidInstallNameException( 'Received: ' . $client_id );
			}

			$user       = $this->sign_on_user_provider->get_wp_user( $user_email );
			$nonce_data = $this->user_nonce_helper->get_nonce_data( $user->ID );

			if ( empty( $nonce_data ) ) {
				throw new NonceMetaDataValidationException( "Empty nonce data retrieved for User ({$user_email}) during login." );
			}

			$is_valid = $this->user_nonce_helper->validate_nonce( $user->ID, $nonce, $nonce_data, $client_id );
			if ( $is_valid ) {
				$this->sign_on_user_provider->login_user( $user, $time_start, $state );
				$redirect_url = self::REDIRECT_URL_ON_SUCCESS;
			}
		} catch ( InvalidInstallNameException $e ) {
			Logger::log( Logger::INSTALL_NAME_ERROR, $e->getMessage(), $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( NonceMetaDataValidationException $e ) {
			Logger::log( Logger::NONCE_META_DATA_VALIDATION_ERROR, $e->getMessage(), $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( MultisiteEnabledException $e ) {
			Logger::log( Logger::MULTISITE_ENABLED_ERROR, $e->getMessage(), null );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( \Exception $e ) {
			Logger::log( Logger::GENERAL_EXCEPTION_ERROR, $e->getMessage() . $e->getTraceAsString(), isset( $user_email ) ? $user_email : null );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		}

		$response = new \WP_REST_Response( null, 307, array( 'Location' => $redirect_url ?? self::REDIRECT_URL_ON_ERROR ) );

		return $response;
	}

	public function is_user_logged_in( $request ) {
		list( $client_id, $user_email, $referer, $state, $redirect_uri ) = $this->get_params_from_is_logged_in_request( $request );

		try {
			if ( $this->is_state_empty( $state ) ) {
				$state_header = self::STATE_ARG;
				Logger::log( Logger::NO_REFERAL_ID_ERROR, "The $state_header http header is empty", $user_email );
			}

			if ( is_multisite() ) {
				throw new MultisiteEnabledException();
			}

			if ( ! is_ssl() && force_ssl_admin() ) {
				return $this->generate_https_redirect( $request->get_query_params() );
			}

			if ( $this->sign_on_user_provider->user_email_matches_current_user( $user_email ) ) {
				$this->user_state_helper->update_state_user_meta( $user_email, $state );
				Logger::log( Logger::USER_LOGGED_IN, "User $user_email already logged in.", $user_email );
				$redirect_url = self::REDIRECT_URL_ON_SUCCESS;
			} else {
				if ( null === $referer ) {
					throw new NoRefererException( 'No referer provided for user logged in check' );
				}
				Logger::log( Logger::USER_NOT_LOGGED_IN, 'User ' . $user_email . ' not logged in. Beginning flow.', $user_email );
				$redirect_url = $referer . '?' . http_build_query( $this->create_is_logged_in_response_params( $client_id, $state, $redirect_uri ) );
			}
		} catch ( InvalidInstallNameException $e ) {
			Logger::log( Logger::INSTALL_NAME_ERROR, $e->getMessage(), $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( NoRefererException $e ) {
			Logger::log( Logger::NO_REFERER_ERROR, $e->getMessage(), $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( MultisiteEnabledException $e ) {
			Logger::log( Logger::MULTISITE_ENABLED_ERROR, $e->getMessage() );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		} catch ( \Exception $e ) {
			Logger::log( Logger::GENERAL_EXCEPTION_ERROR, $e->getMessage(), isset( $user_email ) ? $user_email : null );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
		}

		$response = new \WP_REST_Response( null, 307, array( 'Location' => $redirect_url ?? self::REDIRECT_URL_ON_ERROR ) );

		return $response;
	}

	public function __invoke( $args, $assoc_args ) {
		echo wp_json_encode( $this->wp_sso( $assoc_args ) );
	}

	private function is_state_empty( $state ) {
		return ( ! isset( $state ) || trim( $state ) === '' );
	}

	private function get_params_from_login_request( $request ) {

		$nonce        = $request->get_param( 'nonce' );
		$code   = $request->get_param( 'code' );
		$client_id = $request->get_param( 'client_id' );
		$state   = $request->get_param( self::STATE_ARG );

		return array( $nonce, $code, $client_id, $state );
	}

	private function get_params_from_is_logged_in_request( $request ) {
		$client_id = $request->get_param( 'client_id' );
		$code   = $request->get_param( 'code' );
		$referer      = $request->get_param( 'redirect_url' );
		$redirect_uri      = $request->get_param( 'redirect_uri' );
		$state   = $request->get_param( self::STATE_ARG );
		return array( $client_id, $code, $referer, $state, $redirect_uri );
	}

	private function get_params_from_has_logged_request( $request ) {
		$client_id = $request->get_param( 'client_id' );
		$code   = $request->get_param( 'code' );
		$state   = $request->get_param( self::STATE_ARG );
		return array( $client_id, $code, $state );
	}

	private function wp_sso( $assoc_args ) {
		try {
			if ( is_multisite() ) {
				throw new MultisiteEnabledException();
			}

			$user_email   = $assoc_args[ self::WP_CLI_EMAIL_ARG ];
			$client_id = $assoc_args[ self::WP_CLI_CLIENT_ARG ];
			$first_name   = $assoc_args[ self::WP_CLI_FIRST_NAME_ARG ];
			$last_name    = $assoc_args[ self::WP_CLI_LAST_NAME_ARG ];
			$role         = $assoc_args[ self::WP_CLI_USER_ROLE_ARG ];

			$this->validate_cli_command_params( $user_email, $client_id, $first_name, $last_name, $role );

			$user = $this->sign_on_user_provider->get_or_create_wp_user( $user_email, $first_name, $last_name, $role );

			$nonce_array = $this->user_nonce_helper->generate_nonce( $user->ID );
			$nonce       = $nonce_array['nonce'];
			$expiration  = $nonce_array['expiration'];

			$successfully_added = $this->user_nonce_helper->add_nonce( $user->ID, $nonce, $expiration, $client_id );

			if ( ! $successfully_added ) {
				throw new UserMetaAdditionException( "Nonce ({$nonce}) was not added successfully to users ({$user_email}) meta data" );
			}

			$redirect_url = $this->login_route;
			$query_params = $this->login_params;

		} catch ( UserCreationException $e ) {
			$this->sign_on_user_provider->rollback_user_creation( $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::USER_CREATE_ERROR . ": {$e->getMessage()}";
		} catch ( UserMetaAdditionException $e ) {
			$this->sign_on_user_provider->rollback_user_creation( $user_email );
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::ADD_USER_META_ERROR . ": {$e->getMessage()}";
		} catch ( InvalidInstallNameException $e ) {
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::INSTALL_NAME_ERROR . ": {$e->getMessage()}";
		} catch ( ImpersonatedUserException $e ) {
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::IMPERSONATED_USER_ERROR . ": {$e->getMessage()}";
		} catch ( MultisiteEnabledException $e ) {
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::MULTISITE_ENABLED_ERROR . ": {$e->getMessage()}";
		} catch ( \Exception $e ) {
			$redirect_url = self::REDIRECT_URL_ON_ERROR;
			$error        = Logger::GENERAL_EXCEPTION_ERROR . ": {$e->getMessage()}";
		}

		$data = array(
			'nonce'        => $nonce ?? '',
			'user_email'   => $user->data->user_email ?? '',
			'redirect_url' => $redirect_url,
			'query_params' => $query_params ?? new \stdClass(),
		);

		if ( isset( $error ) ) {
			$this->add_error_field_to_cli_command_return( $data, $error );
		}

		return $data;
	}

	private function add_error_field_to_cli_command_return( &$array, $error ) {
		$array['error_message'] = $error;
	}

	private function validate_cli_command_params( $user_email, $client_id, $first_name, $last_name, $role ) {
		if ( ! $this->validate_non_empty_string( $user_email ) ) {
			throw new \Exception( "User email ({$user_email}) is blank" );
		}

		if ( ! $this->validate_non_empty_string( $first_name ) ) {
			throw new \Exception( 'Validation of CLI command parameters failed as first name was blank.' );
		}

		if ( ! $this->validate_non_empty_string( $last_name ) ) {
			throw new \Exception( 'Validation of CLI command parameters failed as last name was blank.' );
		}

		if ( ! $this->sign_on_user_provider->validate_role( $role ) ) {
			throw new \Exception( "Validation of user role ({$role}) failed as it is not a known WordPress role " );
		}
	}

	private function validate_non_empty_string( $string ) {
		return is_string( $string ) && ! empty( trim( $string ) );
	}

	private function generate_https_redirect( $query_params ) {
		$query_string = http_build_query( $query_params );
		$redirect_url = get_site_url( null, $this->login_route, 'https' );
		$response     = new \WP_REST_Response( null, 307, array( 'Location' => $redirect_url . '?' . $query_string ) );
		return $response;
	}

	private function create_is_logged_in_response_params( $client_id, $state, $redirect_uri ) {
		$params = array(
			'client_id'            => $client_id,
			'redirect_uri'		   => $redirect_uri,
			'initiate'             => true,
			'response_type'		   => 'code',
			'approval_prompt'	   => 'auto',
			self::STATE_ARG => $state,
		);
		return $params;
	}

	/**
     * @param AccessTokenInterface $token
     * @throws BadMethodCallException
     */
    private function handleAccessToken(AccessTokenInterface $token)
    {
        $token = (new JWT\Parser())->parse($token->getToken());

        $sub = $token->getClaim('sub');
        if (!$sub) {
            throw new RuntimeException('Invalid token');
        }

		return $sub;
    }
}
