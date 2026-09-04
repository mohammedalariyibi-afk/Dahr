import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { PUBLIC_ERROR } from "@/lib/public-error";
import { supabaseCookieOptions } from "@/lib/supabase/cookie-options";

export async function updateSession(
  request: NextRequest,
  extraRequestHeaders?: Record<string, string>,
) {
  // Rebuilt on every call: `request.cookies.set` writes through to the cookie
  // header, and a refreshed session must reach the server components below.
  const forwardRequest = () => {
    if (!extraRequestHeaders) return { request };
    const headers = new Headers(request.headers);
    for (const [name, value] of Object.entries(extraRequestHeaders)) {
      headers.set(name, value);
    }
    return { request: { headers } };
  };

  let supabaseResponse = NextResponse.next(forwardRequest());

  /**
   * `getUser()` can rotate the session, and those cookies are written onto
   * `supabaseResponse`. A bare redirect would drop them, so the browser would
   * keep sending the old token — the intermittent-logout footgun in the
   * `@supabase/ssr` guide.
   */
  const redirectTo = (url: URL) => {
    const redirect = NextResponse.redirect(url);
    for (const cookie of supabaseResponse.cookies.getAll()) {
      redirect.cookies.set(cookie);
    }
    return redirect;
  };

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookieOptions: supabaseCookieOptions,
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(
          cookiesToSet: {
            name: string;
            value: string;
            options?: Parameters<typeof supabaseResponse.cookies.set>[2];
          }[],
        ) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next(forwardRequest());
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const isLogin = path === "/login";
  const isAuthCallback = path.startsWith("/auth/");
  // Sign-in endpoints: they are the throttled path to a session, so they must
  // stay reachable without one.
  const isAuthApi = path.startsWith("/api/auth/");
  const isLegal = path === "/privacy" || path === "/terms";
  const isPublic = isLogin || isAuthCallback || isAuthApi || isLegal;

  if (!user && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.delete("error");
    return redirectTo(url);
  }

  let isAdmin = false;
  if (user) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();
    isAdmin = profile?.role === "admin";
  }

  if (user && !isAdmin && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("error", PUBLIC_ERROR.forbidden);
    return redirectTo(url);
  }

  if (user && isAdmin && isLogin) {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    url.searchParams.delete("error");
    return redirectTo(url);
  }

  return supabaseResponse;
}
