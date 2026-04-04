/**
 * ATENA environment configuration for DUA and RIMM services.
 *
 * Each environment maps to a set of SSO, DUA API, and RIMM API URLs
 * with their respective OAuth2 client IDs.
 *
 * @module config/atena-environments
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Configuration for a single ATENA service endpoint. */
export interface AtenaServiceConfig {
  /** OAuth2 SSO token endpoint URL. */
  readonly sso: string;
  /** Base URL for the DUA (declaration) API gateway. */
  readonly duaApi: string;
  /** Base URL for the RIMM reference data API. */
  readonly rimmApi: string;
  /** OAuth2 client_id for DUA operations. */
  readonly duaClientId: string;
  /** OAuth2 client_id for RIMM operations. */
  readonly rimmClientId: string;
}

/** Supported ATENA environment names. */
export type AtenaEnvironment = "dev" | "test" | "preprod" | "prod";

// ---------------------------------------------------------------------------
// Environment configs
// ---------------------------------------------------------------------------

const DEV_CONFIG: AtenaServiceConfig = Object.freeze({
  sso: "https://sso-dev-siaa.hacienda.go.cr/auth/realms/app/protocol/openid-connect/token",
  duaApi: "https://dev-siaa.hacienda.go.cr/cr-sad-server-gateway",
  rimmApi: "https://dev-siaa.hacienda.go.cr/rimm-server",
  duaClientId: "Declaration",
  rimmClientId: "URIMM",
});

const TEST_CONFIG: AtenaServiceConfig = Object.freeze({
  sso: "https://sso-test-siaa.hacienda.go.cr/auth/realms/app/protocol/openid-connect/token",
  duaApi: "https://test-siaa.hacienda.go.cr/cr-sad-server-gateway",
  rimmApi: "https://test-siaa.hacienda.go.cr/rimm-server",
  duaClientId: "Declaration",
  rimmClientId: "URIMM",
});

const PREPROD_CONFIG: AtenaServiceConfig = Object.freeze({
  sso: "https://sso-preprod-siaa.hacienda.go.cr/auth/realms/app/protocol/openid-connect/token",
  duaApi: "https://preprod-siaa.hacienda.go.cr/cr-sad-server-gateway",
  rimmApi: "https://preprod-siaa.hacienda.go.cr/rimm-server",
  duaClientId: "Declaration",
  rimmClientId: "URIMM",
});

const PROD_CONFIG: AtenaServiceConfig = Object.freeze({
  sso: "https://sso-siaa.hacienda.go.cr/auth/realms/app/protocol/openid-connect/token",
  duaApi: "https://siaa.hacienda.go.cr/cr-sad-server-gateway",
  rimmApi: "https://siaa.hacienda.go.cr/rimm-server",
  duaClientId: "Declaration",
  rimmClientId: "URIMM",
});

/** Map of environment name to its configuration. */
const ATENA_ENVIRONMENTS: Readonly<Record<AtenaEnvironment, AtenaServiceConfig>> = Object.freeze({
  dev: DEV_CONFIG,
  test: TEST_CONFIG,
  preprod: PREPROD_CONFIG,
  prod: PROD_CONFIG,
});

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Returns the ATENA service configuration for the given environment.
 *
 * @param env - The target environment name.
 * @returns Immutable configuration object with all URLs and client IDs.
 * @throws {Error} If the environment name is not recognized.
 */
export function getAtenaEnvironment(env: string): AtenaServiceConfig {
  const config = ATENA_ENVIRONMENTS[env as AtenaEnvironment];
  if (!config) {
    throw new Error(
      `Unknown ATENA environment: "${env}". Valid values: ${Object.keys(ATENA_ENVIRONMENTS).join(", ")}`,
    );
  }
  return config;
}

/**
 * Type guard to check if a string is a valid ATENA environment name.
 */
export function isValidAtenaEnvironment(env: string): env is AtenaEnvironment {
  return env in ATENA_ENVIRONMENTS;
}
