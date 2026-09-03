"use client";

import { FormEvent, useState } from "react";
import { useSearchParams } from "next/navigation";
import { PUBLIC_ERROR, publicErrorMessage } from "@/lib/public-error";
import { createClient } from "@/lib/supabase/client";

export default function LoginForm() {
  const searchParams = useSearchParams();
  const errorCode = searchParams.get("error");
  const queryError = publicErrorMessage(errorCode);
  const forbidden = errorCode === PUBLIC_ERROR.forbidden;

  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [sent, setSent] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(queryError);
  const [loading, setLoading] = useState(false);

  async function sendOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setMessage(null);

    const supabase = createClient();
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
        shouldCreateUser: false,
      },
    });

    setLoading(false);
    if (otpError) {
      setError("Could not send a code. Check the email and try again.");
      return;
    }
    setSent(true);
    setMessage("Check your email for a magic link or enter the OTP below.");
  }

  async function verifyOtp(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { error: verifyError } = await supabase.auth.verifyOtp({
      email: email.trim(),
      token: otp.trim(),
      type: "email",
    });

    setLoading(false);
    if (verifyError) {
      setError("Invalid or expired code. Try again.");
      return;
    }
    window.location.href = "/";
  }

  async function signOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    window.location.href = "/login";
  }

  return (
    <main className="min-h-screen flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="mb-10 text-center">
          <p className="font-display text-4xl text-[var(--burgundy)] tracking-tight">
            Dahr
          </p>
          <h1 className="mt-3 text-xl font-medium text-[var(--ink)]">
            Admin sign in
          </h1>
          <p className="mt-2 text-sm text-[var(--muted)]">
            Email magic link or one-time code
          </p>
        </div>

        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] p-6 shadow-sm">
          {forbidden && (
            <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-sm text-red-800">
              <p>This account is not an admin.</p>
              <button
                type="button"
                onClick={signOut}
                className="mt-2 text-[var(--burgundy)] underline underline-offset-2"
              >
                Sign out and try another email
              </button>
            </div>
          )}

          {!sent ? (
            <form onSubmit={sendOtp} className="space-y-4">
              <label className="block text-sm font-medium text-[var(--ink)]">
                Email
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="mt-1.5 w-full rounded-lg border border-[var(--border)] bg-white px-3 py-2.5 text-[var(--ink)] outline-none focus:border-[var(--burgundy)] focus:ring-2 focus:ring-[var(--burgundy-soft)]"
                  placeholder="admin@example.com"
                  autoComplete="email"
                />
              </label>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-lg bg-[var(--burgundy)] px-4 py-2.5 text-sm font-medium text-[var(--cream)] transition hover:bg-[var(--burgundy-deep)] disabled:opacity-60"
              >
                {loading ? "Sending…" : "Send magic link / OTP"}
              </button>
            </form>
          ) : (
            <form onSubmit={verifyOtp} className="space-y-4">
              <p className="text-sm text-[var(--muted)]">
                Code sent to <span className="text-[var(--ink)]">{email}</span>
              </p>
              <label className="block text-sm font-medium text-[var(--ink)]">
                One-time code
                <input
                  type="text"
                  inputMode="numeric"
                  required
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                  className="mt-1.5 w-full rounded-lg border border-[var(--border)] bg-white px-3 py-2.5 tracking-widest text-[var(--ink)] outline-none focus:border-[var(--burgundy)] focus:ring-2 focus:ring-[var(--burgundy-soft)]"
                  placeholder="123456"
                  autoComplete="one-time-code"
                />
              </label>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-lg bg-[var(--burgundy)] px-4 py-2.5 text-sm font-medium text-[var(--cream)] transition hover:bg-[var(--burgundy-deep)] disabled:opacity-60"
              >
                {loading ? "Verifying…" : "Verify & sign in"}
              </button>
              <button
                type="button"
                onClick={() => {
                  setSent(false);
                  setOtp("");
                  setMessage(null);
                  setError(null);
                }}
                className="w-full text-sm text-[var(--muted)] hover:text-[var(--burgundy)]"
              >
                Use a different email
              </button>
            </form>
          )}

          {message && (
            <p className="mt-4 text-sm text-[var(--burgundy)]">{message}</p>
          )}
          {error && <p className="mt-4 text-sm text-red-700">{error}</p>}
        </div>
        <p className="mt-6 text-center text-xs text-[var(--muted)]">
          <a href="/privacy" className="underline underline-offset-2">
            Privacy
          </a>
          {" · "}
          <a href="/terms" className="underline underline-offset-2">
            Terms
          </a>
        </p>
      </div>
    </main>
  );
}
