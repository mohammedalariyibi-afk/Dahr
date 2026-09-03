import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { AdminNav } from "@/components/admin-nav";
import { signOut } from "@/app/(admin)/actions";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role, full_name")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile || profile.role !== "admin") {
    redirect("/login?error=forbidden");
  }

  return (
    <div className="min-h-screen">
      <header className="border-b border-[var(--border)] bg-[var(--surface)]/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
          <div className="flex items-center gap-8">
            <div>
              <p className="font-display text-2xl leading-none text-[var(--burgundy)]">
                Dahr
              </p>
              <p className="mt-0.5 text-xs uppercase tracking-[0.14em] text-[var(--muted)]">
                Admin
              </p>
            </div>
            <AdminNav />
          </div>
          <div className="flex items-center gap-3">
            <span className="hidden text-sm text-[var(--muted)] sm:inline">
              {profile.full_name || user.email}
            </span>
            <form action={signOut}>
              <button
                type="submit"
                className="rounded-lg border border-[var(--border)] px-3 py-1.5 text-sm text-[var(--ink)] transition hover:border-[var(--burgundy)] hover:text-[var(--burgundy)]"
              >
                Sign out
              </button>
            </form>
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6">{children}</main>
    </div>
  );
}
