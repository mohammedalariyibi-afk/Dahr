/** Only in-app relative paths (blocks open redirects on /auth/callback). */
export function safeAdminNextPath(raw: string | null | undefined): string {
  if (!raw) return "/";
  let decoded = raw;
  try {
    decoded = decodeURIComponent(raw);
  } catch {
    return "/";
  }
  if (!decoded.startsWith("/") || decoded.startsWith("//")) return "/";
  return decoded;
}
