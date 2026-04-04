/**
 * gRPC HaciendaSigner service implementation.
 *
 * Wraps the hacienda-sdk's XAdES-EPES signing module. Provides XML
 * signing, sign-and-encode (Base64), and signature verification.
 *
 * @module services/signer-service
 */

import {
  type ServerUnaryCall,
  type sendUnaryData,
} from "@grpc/grpc-js";
import { signXml, signAndEncode } from "@dojocoding/hacienda-sdk";

import type {
  HaciendaSignerServer,
  SignXmlRequest,
  SignXmlResponse,
  SignAndEncodeRequest,
  SignAndEncodeResponse,
  VerifySignatureRequest,
  VerifySignatureResponse,
} from "../generated/hacienda.js";

// ---------------------------------------------------------------------------
// Service implementation
// ---------------------------------------------------------------------------

export const signerService: HaciendaSignerServer = {
  /**
   * Signs an XML document with XAdES-EPES using the provided .p12 certificate.
   *
   * Delegates to hacienda-sdk's signXml which handles:
   * - PKCS#12 loading and key extraction
   * - XAdES-EPES policy and enveloped signature generation
   * - RSA-SHA256 signature algorithm
   */
  signXml(
    call: ServerUnaryCall<SignXmlRequest, SignXmlResponse>,
    callback: sendUnaryData<SignXmlResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const p12Buffer = Buffer.from(req.p12Buffer);
        const signed = await signXml(req.xml, p12Buffer, req.p12Pin);

        callback(null, {
          signedXml: signed,
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          signedXml: "",
          error: message,
        });
      }
    })();
  },

  /**
   * Signs an XML document and returns the result as a Base64-encoded string.
   *
   * This is the pipeline needed for ATENA submission:
   * XML -> XAdES-EPES sign -> Base64 encode.
   */
  signAndEncode(
    call: ServerUnaryCall<SignAndEncodeRequest, SignAndEncodeResponse>,
    callback: sendUnaryData<SignAndEncodeResponse>,
  ): void {
    const req = call.request;

    (async () => {
      try {
        const p12Buffer = Buffer.from(req.p12Buffer);
        const base64 = await signAndEncode(req.xml, p12Buffer, req.p12Pin);

        callback(null, {
          base64SignedXml: base64,
          error: "",
        });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        callback(null, {
          base64SignedXml: "",
          error: message,
        });
      }
    })();
  },

  /**
   * Verifies a signed XML document's signature.
   *
   * Currently performs a structural check for the Signature element
   * and extracts the signer CN. Full cryptographic verification
   * requires the xadesjs verify pipeline (future enhancement).
   */
  verifySignature(
    call: ServerUnaryCall<VerifySignatureRequest, VerifySignatureResponse>,
    callback: sendUnaryData<VerifySignatureResponse>,
  ): void {
    const req = call.request;

    try {
      // Basic structural check: look for the Signature element
      const hasSignature = req.signedXml.includes("<ds:Signature") ||
        req.signedXml.includes("<Signature");

      if (!hasSignature) {
        callback(null, {
          valid: false,
          signerCn: "",
          error: "No XML Signature element found in document.",
        });
        return;
      }

      // Extract CN from X509Certificate or X509SubjectName if present
      let signerCn = "";
      const cnMatch = /CN=([^,<\n]+)/i.exec(req.signedXml);
      if (cnMatch?.[1]) {
        signerCn = cnMatch[1].trim();
      }

      callback(null, {
        valid: true,
        signerCn,
        error: "",
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      callback(null, {
        valid: false,
        signerCn: "",
        error: message,
      });
    }
  },
};
