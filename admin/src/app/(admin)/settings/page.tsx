import { updatePlatformBankDetails } from "@/app/(admin)/actions";
import { ActionError } from "@/components/action-error";
import { createClient } from "@/lib/supabase/server";

type SettingsRow = {
  bank_name: string | null;
  account_holder: string | null;
  account_number: string | null;
  bank_note: string | null;
};

export default async function SettingsPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error: actionError } = await searchParams;
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("platform_settings")
    .select("bank_name, account_holder, account_number, bank_note")
    .eq("id", "default")
    .maybeSingle();

  const row = (data ?? null) as SettingsRow | null;
  const missingTable = Boolean(error);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="font-display text-3xl text-[var(--ink)]">Settings</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Dahr bank details shown to couples for the 10% platform fee. Leave
          empty until Mohammed pastes the real account. Do not invent a Libyan
          account number.
        </p>
      </div>

      <ActionError message={actionError} />

      {missingTable ? (
        <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-900">
          Bank-details table is not on live yet. This is a git-only migration
          (`20260904010000_customer_pays_dahr_fee.sql`). Syber applies it on
          Dahr LY — do not db push from the app PR. Until then, the couple app
          shows “bank details coming from ops”.
        </p>
      ) : (
        <form
          action={updatePlatformBankDetails}
          className="max-w-xl space-y-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-5"
        >
          <label className="block space-y-1.5">
            <span className="text-sm text-[var(--muted)]">Bank name</span>
            <input
              name="bank_name"
              defaultValue={row?.bank_name ?? ""}
              placeholder="Bank name"
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--cream)] px-3 py-2 text-sm text-[var(--ink)]"
            />
          </label>
          <label className="block space-y-1.5">
            <span className="text-sm text-[var(--muted)]">Account holder</span>
            <input
              name="account_holder"
              defaultValue={row?.account_holder ?? ""}
              placeholder="Account holder"
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--cream)] px-3 py-2 text-sm text-[var(--ink)]"
            />
          </label>
          <label className="block space-y-1.5">
            <span className="text-sm text-[var(--muted)]">
              Account number / IBAN
            </span>
            <input
              name="account_number"
              defaultValue={row?.account_number ?? ""}
              placeholder="Account number / IBAN"
              autoComplete="off"
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--cream)] px-3 py-2 text-sm text-[var(--ink)]"
            />
          </label>
          <label className="block space-y-1.5">
            <span className="text-sm text-[var(--muted)]">
              Optional note for the couple
            </span>
            <textarea
              name="bank_note"
              defaultValue={row?.bank_note ?? ""}
              placeholder="Optional note"
              rows={3}
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--cream)] px-3 py-2 text-sm text-[var(--ink)]"
            />
          </label>
          <button
            type="submit"
            className="rounded-md bg-[var(--burgundy)] px-4 py-2 text-sm font-medium text-[var(--cream)] hover:bg-[var(--burgundy-deep)]"
          >
            Save bank details
          </button>
        </form>
      )}
    </div>
  );
}
