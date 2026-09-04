import { NextResponse } from "next/server";
import { PUBLIC_ERROR } from "@/lib/public-error";
import {
  OTP_VERIFY_PER_EMAIL,
  OTP_VERIFY_PER_IP,
  clientIpFromHeaders,
  emailRateKey,
  ipRateKey,
  otpRateLimiter,
} from "@/lib/rate-limit";
import { createClient } from "@/lib/supabase/server";

/**
 * Verifies an admin sign-in code and keeps the session only for an admin.
 *
 * A wrong code and a real-but-non-admin account get the same answer, so a
 * caller learns nothing about the address beyond what they already knew.
 */
export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const email =
    body && typeof body.email === "string" ? body.email.trim() : "";
  const token = body && typeof body.token === "string" ? body.token.trim() : "";

  const ip = clientIpFromHeaders(request.headers);
  const decision = otpRateLimiter.checkAll([
    { key: ipRateKey("otp_verify", ip), rule: OTP_VERIFY_PER_IP },
    { key: emailRateKey("otp_verify", email), rule: OTP_VERIFY_PER_EMAIL },
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

  const failed = NextResponse.json(
    { ok: false, code: PUBLIC_ERROR.signInFailed },
    { status: 400 },
  );

  if (!email || !token) return failed;

  const supabase = await createClient();
  const { data, error } = await supabase.auth.verifyOtp({
    email,
    token,
    type: "email",
  });

  if (error || !data.user) return failed;

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", data.user.id)
    .maybeSingle();

  if (profile?.role !== "admin") {
    // Do not leave a usable dashboard session behind for a non-admin.
    await supabase.auth.signOut();
    return failed;
  }

  return NextResponse.json({ ok: true });
}
