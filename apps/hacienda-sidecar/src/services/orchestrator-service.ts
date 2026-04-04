/**
 * gRPC HaciendaOrchestrator service implementation.
 *
 * Combines auth + sign + API submit into one atomic workflow.
 * Implements the full DUA submission lifecycle:
 * 1. Authenticate with ATENA SSO (if not already)
 * 2. Optionally validate the declaration
 * 3. Sign the DUA XML with XAdES-EPES
 * 4. Submit to ATENA
 * 5. Return the assessment result
 *
 * @module services/orchestrator-service
 */

import {
  type ServerUnaryCall,
  type sendUnaryData,
} from "@grpc/grpc-js";
import {
  TokenManager,
  HttpClient,
  signAndEncode,
} from "@dojocoding/hacienda-sdk";
import type { EnvironmentConfig } from "@dojocoding/hacienda-sdk";

import { getAtenaEnvironment } from "../config/atena-environments.js";
import type {
  HaciendaOrchestratorServer,
  SubmitSignedDeclarationRequest,
  SubmitSignedDeclarationResponse,
} from "../generated/hacienda.js";

// ---------------------------------------------------------------------------
// Username builder (duplicated to keep orchestrator self-contained)
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

export const orchestratorService: HaciendaOrchestratorServer = {
  /**
   * Full workflow: authenticate -> validate (optional) -> sign -> submit -> return result.
   *
   * This is the primary entry point for submitting a signed DUA to ATENA
   * in a single atomic gRPC call.
   */
  submitSignedDeclaration(
    call: ServerUnaryCall<SubmitSignedDeclarationRequest, SubmitSignedDeclarationResponse>,
    callback: sendUnaryData<SubmitSignedDeclarationResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        // 1. Validate auth credentials are provided
        if (!req.auth) {
          callback(null, {
            success: false,
            status: "",
            customsRegistrationNumber: "",
            assessmentSerial: "",
            assessmentNumber: 0,
            assessmentDate: "",
            jsonResponse: "",
            error: "Authentication credentials (auth) are required.",
          });
          return;
        }

        const auth = req.auth;
        const environment = auth.environment || "dev";
        const clientId = auth.clientId || "Declaration";

        // 2. Authenticate with ATENA SSO
        const atenaEnv = getAtenaEnvironment(environment);
        const envConfig: EnvironmentConfig = {
          name: `ATENA ${environment} (${clientId})`,
          apiBaseUrl: atenaEnv.duaApi,
          idpTokenUrl: atenaEnv.sso,
          clientId,
        };

        const tokenManager = new TokenManager({ envConfig });
        const username = buildUsername(auth.idType, auth.idNumber);
        await tokenManager.authenticate({ username, password: auth.password });

        // 3. Create HTTP client for DUA API
        const httpClient = new HttpClient({
          envConfig,
          tokenManager,
        });

        // 4. Parse the DUA payload
        const duaPayload = JSON.parse(req.jsonPayload) as Record<string, unknown>;

        // 5. If validateOnly, just validate and return
        if (req.validateOnly) {
          const validateResponse = await httpClient.post<unknown>(
            "/api/dua/validate",
            duaPayload,
          );

          callback(null, {
            success: true,
            status: "VALIDATED",
            customsRegistrationNumber: "",
            assessmentSerial: "",
            assessmentNumber: 0,
            assessmentDate: "",
            jsonResponse: JSON.stringify(validateResponse.data),
            error: "",
          });
          return;
        }

        // 6. Sign the DUA XML if present in payload
        if (duaPayload["xml"] && typeof duaPayload["xml"] === "string") {
          const p12Buffer = Buffer.from(req.p12Buffer);
          const signedBase64 = await signAndEncode(
            duaPayload["xml"] as string,
            p12Buffer,
            req.p12Pin,
          );
          duaPayload["signedXml"] = signedBase64;
        }

        // 7. Submit (liquidate) the declaration
        const submitResponse = await httpClient.post<Record<string, unknown>>(
          "/api/dua/liquidate",
          duaPayload,
        );

        const responseData = submitResponse.data;

        callback(null, {
          success: true,
          status: String(responseData["status"] ?? ""),
          customsRegistrationNumber: String(responseData["customsRegistrationNumber"] ?? ""),
          assessmentSerial: String(responseData["assessmentSerial"] ?? ""),
          assessmentNumber: Number(responseData["assessmentNumber"] ?? 0),
          assessmentDate: String(responseData["assessmentDate"] ?? ""),
          jsonResponse: JSON.stringify(responseData),
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          success: false,
          status: "",
          customsRegistrationNumber: "",
          assessmentSerial: "",
          assessmentNumber: 0,
          assessmentDate: "",
          jsonResponse: "",
          error: message,
        });
      }
    })();
  },
};
