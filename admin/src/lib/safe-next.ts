/**
 * Auth callback `next` must stay on this origin as a relative path.
 * Rejects protocol-relative URLs, userinfo tricks, and backslashes.
 */
export function safeNextPath(raw: string | null | undefined): string {
  if (!raw) return "/";
  let value = raw.trim();
  try {
    value = decodeURIComponent(value);
  } catch {
    return "/";
  }
  if (!value.startsWith("/")) return "/";
  if (value.startsWith("//")) return "/";
  if (value.includes("://") || value.includes("\\") || value.includes("@")) {
    return "/";
  }
  if (value.includes("\0")) return "/";
  return value;
}

export function safeRedirectUrl(origin: string, next: string | null | undefined): URL {
  const path = safeNextPath(next);
  const url = new URL(path, origin);
  if (url.origin !== origin) {
    return new URL("/", origin);
  }
  return url;
}
