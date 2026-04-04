/**
 * AduaNext Hacienda gRPC Sidecar — Main entry point.
 *
 * Creates a gRPC server on port 50051 (configurable via GRPC_PORT env var),
 * registers all 4 Hacienda services, and starts listening.
 *
 * Services:
 * - HaciendaAuth: OIDC ROPC token management
 * - HaciendaSigner: XAdES-EPES XML signing
 * - HaciendaApi: ATENA DUA + RIMM REST proxy
 * - HaciendaOrchestrator: Atomic auth + sign + submit workflow
 *
 * @module index
 */

import * as grpc from "@grpc/grpc-js";

import {
  HaciendaAuthService,
  HaciendaSignerService,
  HaciendaApiService,
  HaciendaOrchestratorService,
} from "./generated/hacienda.js";
import { authService } from "./services/auth-service.js";
import { signerService } from "./services/signer-service.js";
import { apiService } from "./services/api-service.js";
import { orchestratorService } from "./services/orchestrator-service.js";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const GRPC_PORT = process.env["GRPC_PORT"] ?? "50051";
const GRPC_HOST = process.env["GRPC_HOST"] ?? "0.0.0.0";

// ---------------------------------------------------------------------------
// Server bootstrap
// ---------------------------------------------------------------------------

function createServer(): grpc.Server {
  const server = new grpc.Server({
    // Max message size: 50MB (for document uploads)
    "grpc.max_receive_message_length": 50 * 1024 * 1024,
    "grpc.max_send_message_length": 50 * 1024 * 1024,
  });

  // Register all 4 services
  server.addService(HaciendaAuthService, authService);
  server.addService(HaciendaSignerService, signerService);
  server.addService(HaciendaApiService, apiService);
  server.addService(HaciendaOrchestratorService, orchestratorService);

  return server;
}

function startServer(server: grpc.Server): void {
  const address = `${GRPC_HOST}:${GRPC_PORT}`;

  server.bindAsync(
    address,
    grpc.ServerCredentials.createInsecure(),
    (error, port) => {
      if (error) {
        console.error(`Failed to bind gRPC server: ${error.message}`);
        process.exit(1);
      }

      console.log(`Hacienda gRPC sidecar listening on ${GRPC_HOST}:${String(port)}`);
      console.log("Services registered:");
      console.log("  - HaciendaAuth     (auth, token management)");
      console.log("  - HaciendaSigner   (XAdES-EPES signing)");
      console.log("  - HaciendaApi      (ATENA DUA + RIMM proxy)");
      console.log("  - HaciendaOrchestrator (atomic submit workflow)");
    },
  );
}

// ---------------------------------------------------------------------------
// Graceful shutdown
// ---------------------------------------------------------------------------

function setupGracefulShutdown(server: grpc.Server): void {
  const shutdown = (signal: string): void => {
    console.log(`\nReceived ${signal}. Shutting down gRPC server gracefully...`);
    server.tryShutdown((error) => {
      if (error) {
        console.error(`Error during shutdown: ${error.message}`);
        server.forceShutdown();
      }
      console.log("gRPC server stopped.");
      process.exit(0);
    });
  };

  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const server = createServer();
setupGracefulShutdown(server);
startServer(server);
