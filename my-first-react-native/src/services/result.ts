export type ServiceErrorCode = "NOT_FOUND" | "SEATS_TAKEN" | "NETWORK";

export type ServiceError = {
  code: ServiceErrorCode;
  message: string;
};

export type Result<T> = { ok: true; data: T } | { ok: false; error: ServiceError };

export function ok<T>(data: T): Result<T> {
  return { ok: true, data };
}

export function err<T = never>(code: ServiceErrorCode, message: string): Result<T> {
  console.error(`[${code}] ${message}`);
  return { ok: false, error: { code, message } };
}
