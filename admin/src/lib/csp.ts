/** Content-Security-Policy for the admin dashboard (launch audit M8).
 *
 * Nonce-based: Next.js reads the nonce out of this header and stamps it on the
 * scripts it injects, so no `unsafe-inline` is needed for script execution.
 */

export type CspOptions = {
  nonce: string;
  /** `NEXT_PUBLIC_SUPABASE_URL`. Its origin is the only allowed API host. */
  supabaseUrl?: string | null;
  /** `next dev` needs eval for hot reload; production must not have it. */
  isDev?: boolean;
};

export function supabaseOrigins(supabaseUrl?: string | null): string[] {
  if (!supabaseUrl) return [];
  try {
    const url = new URL(supabaseUrl);
    const wsScheme = url.protocol === "http:" ? "ws:" : "wss:";
    return [url.origin, `${wsScheme}//${url.host}`];
  } catch {
    return [];
  }
}

export function buildCsp({
  nonce,
  supabaseUrl,
  isDev = false,
}: CspOptions): string {
  const [apiOrigin, realtimeOrigin] = supabaseOrigins(supabaseUrl);

  const scriptSrc = [
    "'self'",
    `'nonce-${nonce}'`,
    // Lets Next's nonced bootstrap load the chunks it needs in browsers that
    // support it, without listing every hashed filename.
    "'strict-dynamic'",
    ...(isDev ? ["'unsafe-eval'"] : []),
  ];

  const connectSrc = [
    "'self'",
    ...(apiOrigin ? [apiOrigin] : []),
    ...(realtimeOrigin ? [realtimeOrigin] : []),
  ];

  const imgSrc = ["'self'", "data:", "blob:", ...(apiOrigin ? [apiOrigin] : [])];

  const directives: [string, string[]][] = [
    ["default-src", ["'self'"]],
    ["script-src", scriptSrc],
    // Tailwind ships a stylesheet, but Next still inlines critical CSS.
    ["style-src", ["'self'", "'unsafe-inline'"]],
    ["img-src", imgSrc],
    ["font-src", ["'self'", "data:"]],
    ["connect-src", connectSrc],
    ["form-action", ["'self'"]],
    ["frame-ancestors", ["'none'"]],
    ["base-uri", ["'self'"]],
    ["object-src", ["'none'"]],
    ["worker-src", ["'self'", "blob:"]],
    ["manifest-src", ["'self'"]],
  ];

  const policy = directives
    .map(([name, values]) => `${name} ${values.join(" ")}`)
    .join("; ");

  return isDev ? policy : `${policy}; upgrade-insecure-requests`;
}

export function createNonce(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes));
}
