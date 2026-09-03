import { publicErrorMessage } from "@/lib/public-error";

export function ActionError({ message }: { message?: string | string[] }) {
  const raw = Array.isArray(message) ? message[0] : message;
  const text = publicErrorMessage(raw);
  if (!text) return null;

  return (
    <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
      {text}
    </p>
  );
}
