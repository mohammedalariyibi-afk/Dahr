import { NextResponse } from "next/server";
import { PUBLIC_ERROR } from "@/lib/public-error";
import {
  OTP_SEND_PER_EMAIL,
  OTP_SEND_PER_IP,
  clientIpFromHeaders,
  emailRateKey,
  ipRateKey,
  otpRateLimiter,
} from "@/lib/rate-limit";
import { createClient } from "@/lib/supabase/server";

const EMAIL_SHAPE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Sends an admin sign-in code.
 *
 * Always answers `{ ok: true }` unless the caller is throttled: a per-address
 * response would say whether that address has a Dahr account
 * (`shouldCreateUser: false` fails for unknown users).
 */
export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const email =
    body && typeof body.email === "string" ? body.email.trim() : "";

  const ip = clientIpFromHeaders(request.headers);
  const decision = otpRateLimiter.checkAll([
    { key: ipRateKey("otp_send", ip), rule: OTP_SEND_PER_IP },
    { key: emailRateKey("otp_send", email), rule: OTP_SEND_PER_EMAIL },
  ]);

  if (!decision.allowed) {
    return NextResponse.json(
      { ok: false, code: PUBLIC_ERROR.rateLimited },
      {
        status: 429,
        headers: { "Retry-After": String(decision.retryAfterSeconds) },
      },
    );
  }

  if (EMAIL_SHAPE.test(email)) {
    const { origin } = new URL(request.url);
    const supabase = await createClient();
    await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${origin}/auth/callback`,
        shouldCreateUser: false,
      },
    });
  }

  return NextResponse.json({ ok: true });
}
