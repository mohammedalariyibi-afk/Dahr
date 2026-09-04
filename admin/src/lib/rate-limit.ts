/** Fixed-window rate limiting for the admin sign-in endpoints.
 *
 * Supabase Auth has its own limits; this is the app-level throttle the launch
 * audit asked for (M6) so a public admin origin cannot be used to spray OTP
 * mail at arbitrary addresses. State is per server instance and in memory: it
 * raises the cost of a spray without a shared store, and it is deliberately
 * fail-closed only for the request that trips it.
 */

export type RateLimitRule = {
  limit: number;
  windowMs: number;
};

export type RateLimitDecision = {
  allowed: boolean;
  remaining: number;
  retryAfterSeconds: number;
};

const MINUTE = 60_000;

/** Per e-mail: an operator needs one code, not ten. */
export const OTP_SEND_PER_EMAIL: RateLimitRule = {
  limit: 3,
  windowMs: 15 * MINUTE,
};

/** Per source address, so one host cannot walk a list of addresses. */
export const OTP_SEND_PER_IP: RateLimitRule = {
  limit: 10,
  windowMs: 15 * MINUTE,
};

/** Verify is cheap to retry, so the cap is about guessing the 6 digits. */
export const OTP_VERIFY_PER_EMAIL: RateLimitRule = {
  limit: 8,
  windowMs: 15 * MINUTE,
};

export const OTP_VERIFY_PER_IP: RateLimitRule = {
  limit: 20,
  windowMs: 15 * MINUTE,
};

type Window = { count: number; resetAt: number };

export class FixedWindowRateLimiter {
  /** Bounded so a spray of unique keys cannot grow the heap without limit. */
  constructor(private readonly maxKeys = 10_000) {}

  private readonly windows = new Map<string, Window>();

  check(
    key: string,
    rule: RateLimitRule,
    now: number = Date.now(),
  ): RateLimitDecision {
    this.prune(now);

    const current = this.windows.get(key);
    if (!current || current.resetAt <= now) {
      this.windows.set(key, { count: 1, resetAt: now + rule.windowMs });
      return {
        allowed: true,
        remaining: rule.limit - 1,
        retryAfterSeconds: 0,
      };
    }

    if (current.count >= rule.limit) {
      return {
        allowed: false,
        remaining: 0,
        retryAfterSeconds: Math.max(
          1,
          Math.ceil((current.resetAt - now) / 1000),
        ),
      };
    }

    current.count += 1;
    return {
      allowed: true,
      remaining: rule.limit - current.count,
      retryAfterSeconds: 0,
    };
  }

  /** Every rule must pass, and only the first failure is reported. */
  checkAll(
    checks: { key: string; rule: RateLimitRule }[],
    now: number = Date.now(),
  ): RateLimitDecision {
    let worst: RateLimitDecision = {
      allowed: true,
      remaining: Number.MAX_SAFE_INTEGER,
      retryAfterSeconds: 0,
    };
    for (const { key, rule } of checks) {
      const decision = this.check(key, rule, now);
      if (!decision.allowed) return decision;
      if (decision.remaining < worst.remaining) worst = decision;
    }
    return worst;
  }

  reset() {
    this.windows.clear();
  }

  private prune(now: number) {
    for (const [key, window] of this.windows) {
      if (window.resetAt <= now) this.windows.delete(key);
    }
    if (this.windows.size <= this.maxKeys) return;
    const overflow = this.windows.size - this.maxKeys;
    let dropped = 0;
    for (const key of this.windows.keys()) {
      this.windows.delete(key);
      if (++dropped >= overflow) break;
    }
  }
}

/** Module scope so the windows survive between requests on one instance. */
export const otpRateLimiter = new FixedWindowRateLimiter();

/** Normalized so casing and padding cannot buy extra attempts. */
export function emailRateKey(prefix: string, email: string): string {
  return `${prefix}:email:${email.trim().toLowerCase()}`;
}

export function ipRateKey(prefix: string, ip: string): string {
  return `${prefix}:ip:${ip}`;
}

/**
 * Trusts `x-forwarded-for` only for the client-most entry, which is what a
 * single reverse proxy (Vercel, Nginx) sets. Unknown sources share one bucket
 * rather than escaping the limit.
 */
export function clientIpFromHeaders(headers: Headers): string {
  const forwarded = headers.get("x-forwarded-for");
  if (forwarded) {
    const first = forwarded.split(",")[0]?.trim();
    if (first) return first;
  }
  return headers.get("x-real-ip")?.trim() || "unknown";
}
