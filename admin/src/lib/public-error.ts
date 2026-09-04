/** Query-string / UI codes. Never put PostgREST text in a URL. */
export const PUBLIC_ERROR = {
  forbidden: "forbidden",
  auth: "auth",
  writeFailed: "write_failed",
  loadFailed: "load_failed",
  rateLimited: "rate_limited",
  signInFailed: "sign_in_failed",
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
    case PUBLIC_ERROR.rateLimited:
      return "Too many sign-in attempts. Wait a few minutes and try again.";
    // Deliberately says nothing about whether the address exists or is an
    // admin: the same copy covers a wrong code and a non-admin account.
    case PUBLIC_ERROR.signInFailed:
      return "Could not sign in to the dashboard. Check the code and try again.";
    default:
      return null;
  }
}

export function isPublicErrorCode(code: string | null | undefined): code is PublicErrorCode {
  return publicErrorMessage(code) !== null;
}
