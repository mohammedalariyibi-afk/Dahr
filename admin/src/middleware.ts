import { NextResponse, type NextRequest } from "next/server";
import { buildCsp, createNonce } from "@/lib/csp";
import { updateSession } from "@/lib/supabase/middleware";

const PUBLIC_PATHS = ["/privacy", "/terms"];

function withHeaders(base: Headers, extra: Record<string, string>): Headers {
  const headers = new Headers(base);
  for (const [name, value] of Object.entries(extra)) {
    headers.set(name, value);
  }
  return headers;
}

export async function middleware(request: NextRequest) {
  const nonce = createNonce();
  const csp = buildCsp({
    nonce,
    supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
    isDev: process.env.NODE_ENV !== "production",
  });

  // Next.js reads the nonce back out of the CSP header to stamp its own
  // scripts; `x-nonce` is for anything a page renders itself.
  const requestHeaders = {
    "x-nonce": nonce,
    "content-security-policy": csp,
  };

  const path = request.nextUrl.pathname;
  const response = PUBLIC_PATHS.includes(path)
    ? NextResponse.next({ request: { headers: withHeaders(request.headers, requestHeaders) } })
    : await updateSession(request, requestHeaders);

  response.headers.set("Content-Security-Policy", csp);
  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
