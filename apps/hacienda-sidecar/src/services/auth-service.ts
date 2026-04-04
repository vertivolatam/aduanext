/**
 * gRPC HaciendaAuth service implementation.
 *
 * Wraps the hacienda-sdk's TokenManager for OIDC ROPC token management
 * against the ATENA SSO endpoints. Manages separate token managers per
 * client_id (Declaration vs URIMM) to support independent auth sessions.
 *
 * @module services/auth-service
 */

import {
  type ServerUnaryCall,
  type sendUnaryData,
  status as GrpcStatus,
} from "@grpc/grpc-js";
import { TokenManager } from "@dojocoding/hacienda-sdk";
import type { EnvironmentConfig } from "@dojocoding/hacienda-sdk";

import { getAtenaEnvironment } from "../config/atena-environments.js";
import type {
  AuthenticateRequest,
  AuthenticateResponse,
  GetAccessTokenRequest,
  GetAccessTokenResponse,
  HaciendaAuthServer,
  InvalidateRequest,
  InvalidateResponse,
  IsAuthenticatedRequest,
  IsAuthenticatedResponse,
} from "../generated/hacienda.js";

// ---------------------------------------------------------------------------
// Token manager registry
// ---------------------------------------------------------------------------

/**
 * Composite key for the token manager registry: `${environment}:${clientId}`.
 */
function managerKey(environment: string, clientId: string): string {
  return `${environment}:${clientId}`;
}

/**
 * In-memory registry of TokenManager instances keyed by environment + clientId.
 * Each unique (env, clientId) pair gets its own independent session.
 */
const tokenManagers = new Map<string, TokenManager>();

/**
 * Retrieves or creates a TokenManager for the given environment + clientId pair.
 */
function getOrCreateManager(environment: string, clientId: string): TokenManager {
  const key = managerKey(environment, clientId);
  let manager = tokenManagers.get(key);
  if (!manager) {
    const atenaEnv = getAtenaEnvironment(environment);
    const envConfig: EnvironmentConfig = {
      name: `ATENA ${environment} (${clientId})`,
      apiBaseUrl: clientId === "URIMM" ? atenaEnv.rimmApi : atenaEnv.duaApi,
      idpTokenUrl: atenaEnv.sso,
      clientId,
    };
    manager = new TokenManager({ envConfig });
    tokenManagers.set(key, manager);
  }
  return manager;
}

/**
 * Retrieves an existing TokenManager for the given clientId.
 * Searches across all environments (returns first match).
 */
function findManagerByClientId(clientId: string): TokenManager | undefined {
  for (const [key, manager] of tokenManagers.entries()) {
    if (key.endsWith(`:${clientId}`)) {
      return manager;
    }
  }
  return undefined;
}

// ---------------------------------------------------------------------------
// Build the Hacienda username from id_type + id_number
// ---------------------------------------------------------------------------

const ID_TYPE_PREFIX: Readonly<Record<string, string>> = {
  "01": "cpf",
  "02": "cpj",
  "03": "cpf",
  "04": "cpf",
};

function buildUsername(idType: string, idNumber: string): string {
  const prefix = ID_TYPE_PREFIX[idType];
  if (!prefix) {
    throw new Error(`Invalid idType: "${idType}". Must be 01, 02, 03, or 04.`);
  }
  return `${prefix}-${idType}-${idNumber}`;
}

// ---------------------------------------------------------------------------
// Service implementation
// ---------------------------------------------------------------------------

export const authService: HaciendaAuthServer = {
  /**
   * Authenticate with ATENA SSO using ROPC credentials.
   *
   * Creates (or retrieves) a TokenManager for the given environment + clientId
   * and performs the initial password-grant authentication.
   */
  authenticate(
    call: ServerUnaryCall<AuthenticateRequest, AuthenticateResponse>,
    callback: sendUnaryData<AuthenticateResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const manager = getOrCreateManager(req.environment, req.clientId);
        const username = buildUsername(req.idType, req.idNumber);

        await manager.authenticate({ username, password: req.password });

        callback(null, {
          success: true,
          message: `Authenticated with ${req.clientId} on ${req.environment}`,
          errorCode: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          success: false,
          message,
          errorCode: "AUTH_FAILED",
        });
      }
    })();
  },

  /**
   * Get a cached access token (auto-refreshes 30s before expiry).
   *
   * Looks up the TokenManager for the requested clientId and returns
   * the current valid JWT.
   */
  getAccessToken(
    call: ServerUnaryCall<GetAccessTokenRequest, GetAccessTokenResponse>,
    callback: sendUnaryData<GetAccessTokenResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const manager = findManagerByClientId(req.clientId);
        if (!manager) {
          callback({
            code: GrpcStatus.UNAUTHENTICATED,
            message: `No active session for clientId "${req.clientId}". Call Authenticate first.`,
            name: "UNAUTHENTICATED",
            details: "",
            metadata: call.metadata,
          });
          return;
        }

        const token = await manager.getAccessToken();

        callback(null, {
          token,
          expiresInSeconds: 300, // approximate; SDK manages exact refresh
          tokenType: "Bearer",
          scope: "profile email",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback({
          code: GrpcStatus.UNAUTHENTICATED,
          message,
          name: "UNAUTHENTICATED",
          details: "",
          metadata: call.metadata,
        });
      }
    })();
  },

  /**
   * Check if a valid session exists for the given clientId.
   */
  isAuthenticated(
    call: ServerUnaryCall<IsAuthenticatedRequest, IsAuthenticatedResponse>,
    callback: sendUnaryData<IsAuthenticatedResponse>,
  ): void {
    const req = call.request;
    const manager = findManagerByClientId(req.clientId);
    callback(null, {
      authenticated: manager?.isAuthenticated ?? false,
    });
  },

  /**
   * Invalidate the current session for the given clientId.
   */
  invalidate(
    call: ServerUnaryCall<InvalidateRequest, InvalidateResponse>,
    callback: sendUnaryData<InvalidateResponse>,
  ): void {
    const req = call.request;
    const manager = findManagerByClientId(req.clientId);
    if (manager) {
      manager.invalidate();
    }
    callback(null, { success: true });
  },
};
