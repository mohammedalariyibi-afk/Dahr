/** Query-string / UI codes. Never put PostgREST text in a URL. */
export const PUBLIC_ERROR = {
  forbidden: "forbidden",
  auth: "auth",
  writeFailed: "write_failed",
  loadFailed: "load_failed",
} as const;

export type PublicErrorCode = (typeof PUBLIC_ERROR)[keyof typeof PUBLIC_ERROR];

export function publicErrorMessage(code: string | null | undefined): string | null {
  switch (code) {
    case PUBLIC_ERROR.forbidden:
      return "This account is not an admin.";
    case PUBLIC_ERROR.auth:
      return "Magic link expired or invalid. Try again.";
    case PUBLIC_ERROR.writeFailed:
      return "Could not save that change. Try again.";
    case PUBLIC_ERROR.loadFailed:
      return "Could not load this page. Try again.";
    default:
      return null;
  }
}

export function isPublicErrorCode(code: string | null | undefined): code is PublicErrorCode {
  return publicErrorMessage(code) !== null;
}
