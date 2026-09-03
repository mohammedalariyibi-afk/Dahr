import { Suspense } from "react";
import LoginForm from "./login-form";

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <main className="min-h-screen flex items-center justify-center px-4">
          <p className="text-sm text-[var(--muted)]">Loading…</p>
        </main>
      }
    >
      <LoginForm />
    </Suspense>
  );
}
