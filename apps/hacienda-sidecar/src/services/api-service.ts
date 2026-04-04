/**
 * gRPC HaciendaApi service implementation.
 *
 * Wraps the hacienda-sdk's HttpClient for ATENA REST API calls.
 * Supports DUA operations (get, validate, liquidate, rectify, upload)
 * and RIMM reference data search.
 *
 * The service requires active authentication sessions (via HaciendaAuth)
 * before making API calls. It constructs HttpClient instances on-demand
 * using cached TokenManagers.
 *
 * @module services/api-service
 */

import {
  type ServerUnaryCall,
  type sendUnaryData,
  status as GrpcStatus,
} from "@grpc/grpc-js";
import { TokenManager, HttpClient } from "@dojocoding/hacienda-sdk";
import type { EnvironmentConfig } from "@dojocoding/hacienda-sdk";

import { getAtenaEnvironment } from "../config/atena-environments.js";
import type {
  ApiResponse,
  GetDeclarationRequest,
  GetDeclarationResponse,
  HaciendaApiServer,
  LiquidateDeclarationRequest,
  RectifyDeclarationRequest,
  RimmSearchRequest,
  RimmSearchResponse,
  UploadDocumentRequest,
  ValidateDeclarationRequest,
  ValidateRectificationRequest,
} from "../generated/hacienda.js";

// ---------------------------------------------------------------------------
// Shared state — mirrors auth-service's registry
// ---------------------------------------------------------------------------

/**
 * Active environment context for API calls.
 * Set during Authenticate and used by API methods.
 */
interface ApiSession {
  readonly environment: string;
  readonly tokenManager: TokenManager;
  readonly duaClient: HttpClient;
  readonly rimmClient: HttpClient;
}

const sessions = new Map<string, ApiSession>();

/**
 * Registers an authenticated session for API use.
 * Called internally when auth-service authenticates.
 */
export function registerApiSession(
  environment: string,
  clientId: string,
  tokenManager: TokenManager,
): void {
  const atenaEnv = getAtenaEnvironment(environment);
  const key = `${environment}:${clientId}`;

  // Only create the session if not already exists
  if (!sessions.has(key)) {
    const duaEnvConfig: EnvironmentConfig = {
      name: `ATENA DUA ${environment}`,
      apiBaseUrl: atenaEnv.duaApi,
      idpTokenUrl: atenaEnv.sso,
      clientId: atenaEnv.duaClientId,
    };

    const rimmEnvConfig: EnvironmentConfig = {
      name: `ATENA RIMM ${environment}`,
      apiBaseUrl: atenaEnv.rimmApi,
      idpTokenUrl: atenaEnv.sso,
      clientId: atenaEnv.rimmClientId,
    };

    sessions.set(key, {
      environment,
      tokenManager,
      duaClient: new HttpClient({ envConfig: duaEnvConfig, tokenManager }),
      rimmClient: new HttpClient({ envConfig: rimmEnvConfig, tokenManager }),
    });
  }
}

/**
 * Finds the first active API session for the given clientId (across environments).
 */
function findSession(clientId: string): ApiSession | undefined {
  for (const [key, session] of sessions.entries()) {
    if (key.endsWith(`:${clientId}`)) {
      return session;
    }
  }
  // Fallback: return any active DUA session
  for (const session of sessions.values()) {
    return session;
  }
  return undefined;
}

/**
 * Gets the DUA HttpClient from an active session, or returns a gRPC error.
 */
function getDuaClient(
  call: ServerUnaryCall<unknown, unknown>,
  callback: sendUnaryData<unknown>,
): HttpClient | null {
  const session = findSession("Declaration");
  if (!session) {
    callback({
      code: GrpcStatus.FAILED_PRECONDITION,
      message: "No active DUA session. Call Authenticate with clientId='Declaration' first.",
      name: "FAILED_PRECONDITION",
      details: "",
      metadata: call.metadata,
    });
    return null;
  }
  return session.duaClient;
}

// ---------------------------------------------------------------------------
// Service implementation
// ---------------------------------------------------------------------------

export const apiService: HaciendaApiServer = {
  /**
   * DUA API #1: Get declaration by registration key.
   *
   * GET /api/dua/{customsOfficeCode}/{serial}/{number}/{year}
   */
  getDeclaration(
    call: ServerUnaryCall<GetDeclarationRequest, GetDeclarationResponse>,
    callback: sendUnaryData<GetDeclarationResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        const path = `/api/dua/${req.customsOfficeCode}/${req.serial}/${String(req.number)}/${String(req.year)}`;
        const response = await client.get<unknown>(path);

        callback(null, {
          jsonPayload: JSON.stringify(response.data),
          httpStatus: response.status,
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          jsonPayload: "",
          httpStatus: 0,
          error: message,
        });
      }
    })();
  },

  /**
   * DUA API #2: Validate declaration for liquidation.
   *
   * POST /api/dua/validate
   */
  validateDeclaration(
    call: ServerUnaryCall<ValidateDeclarationRequest, ApiResponse>,
    callback: sendUnaryData<ApiResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        const body = JSON.parse(req.jsonPayload) as unknown;
        const response = await client.post<unknown>("/api/dua/validate", body);

        callback(null, {
          httpStatus: response.status,
          jsonPayload: JSON.stringify(response.data),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          httpStatus: 0,
          jsonPayload: "",
          error: message,
        });
      }
    })();
  },

  /**
   * DUA API #3: Liquidate (assess) declaration.
   *
   * POST /api/dua/liquidate
   */
  liquidateDeclaration(
    call: ServerUnaryCall<LiquidateDeclarationRequest, ApiResponse>,
    callback: sendUnaryData<ApiResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        const body = JSON.parse(req.jsonPayload) as unknown;
        const response = await client.post<unknown>("/api/dua/liquidate", body);

        callback(null, {
          httpStatus: response.status,
          jsonPayload: JSON.stringify(response.data),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          httpStatus: 0,
          jsonPayload: "",
          error: message,
        });
      }
    })();
  },

  /**
   * DUA API #4: Validate DUA for rectification.
   *
   * POST /api/dua/rectification/validate
   */
  validateRectification(
    call: ServerUnaryCall<ValidateRectificationRequest, ApiResponse>,
    callback: sendUnaryData<ApiResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        const body = JSON.parse(req.jsonPayload) as unknown;
        const response = await client.post<unknown>("/api/dua/rectification/validate", body);

        callback(null, {
          httpStatus: response.status,
          jsonPayload: JSON.stringify(response.data),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          httpStatus: 0,
          jsonPayload: "",
          error: message,
        });
      }
    })();
  },

  /**
   * DUA API #5: Rectify declaration.
   *
   * POST /api/dua/rectification
   */
  rectifyDeclaration(
    call: ServerUnaryCall<RectifyDeclarationRequest, ApiResponse>,
    callback: sendUnaryData<ApiResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        const body = JSON.parse(req.jsonPayload) as unknown;
        const response = await client.post<unknown>("/api/dua/rectification", body);

        callback(null, {
          httpStatus: response.status,
          jsonPayload: JSON.stringify(response.data),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          httpStatus: 0,
          jsonPayload: "",
          error: message,
        });
      }
    })();
  },

  /**
   * DUA API #6: Upload attached document.
   *
   * POST /api/dua/{declarationId}/documents
   * Sends multipart/form-data with file content.
   */
  uploadDocument(
    call: ServerUnaryCall<UploadDocumentRequest, ApiResponse>,
    callback: sendUnaryData<ApiResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const client = getDuaClient(call, callback as sendUnaryData<unknown>);
        if (!client) return;

        // Build the upload payload as JSON (ATENA gateway accepts JSON with base64 content)
        const body = {
          docCode: req.docCode,
          docReference: req.docReference,
          fileName: req.fileName,
          contentType: req.contentType,
          fileContent: Buffer.from(req.fileContent).toString("base64"),
        };

        const path = `/api/dua/${req.declarationId}/documents`;
        const response = await client.post<unknown>(path, body);

        callback(null, {
          httpStatus: response.status,
          jsonPayload: JSON.stringify(response.data),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          httpStatus: 0,
          jsonPayload: "",
          error: message,
        });
      }
    })();
  },

  /**
   * RIMM: Generic search across any reference table.
   *
   * POST /api/rimm/{endpoint}/search
   * Uses the documented RIMM request pattern with restrictions, meta,
   * pagination, and sorting.
   */
  rimmSearch(
    call: ServerUnaryCall<RimmSearchRequest, RimmSearchResponse>,
    callback: sendUnaryData<RimmSearchResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        // For RIMM, look for a URIMM session first, then fallback
        let session = findSession("URIMM");
        if (!session) {
          session = findSession("Declaration");
        }
        if (!session) {
          callback({
            code: GrpcStatus.FAILED_PRECONDITION,
            message: "No active RIMM session. Call Authenticate with clientId='URIMM' first.",
            name: "FAILED_PRECONDITION",
            details: "",
            metadata: call.metadata,
          });
          return;
        }

        // Build the RIMM search request body
        const restrictions = req.restrictions.map((r) => ({
          value: r.value,
          operator: r.operator,
          field: r.field,
          valueTo: r.valueTo || undefined,
        }));

        const meta = req.meta
          ? { operator: req.meta.operator, validityDate: req.meta.validityDate }
          : undefined;

        // Convert sortByFields map to plain object
        const sortByFields: Record<string, string> = {};
        for (const [key, value] of Object.entries(req.sortByFields)) {
          sortByFields[key] = value;
        }

        const body = {
          restrictions,
          meta,
          max: req.max || 100,
          offset: req.offset || 0,
          distinct: req.distinct,
          restrictBy: req.restrictBy || "AND",
          selectFields: req.selectFields.length > 0 ? req.selectFields : ["*"],
          sortByFields,
        };

        const path = `/api/rimm/${req.endpoint}/search`;
        const response = await session.rimmClient.post<{
          resultList?: unknown[];
          totalCount?: number;
        }>(path, body);

        const resultList = (response.data.resultList ?? []).map((item) =>
          JSON.stringify(item),
        );

        callback(null, {
          resultList,
          totalCount: response.data.totalCount ?? resultList.length,
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          resultList: [],
          totalCount: 0,
          error: message,
        });
      }
    })();
  },
};
