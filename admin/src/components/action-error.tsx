export function ActionError({ message }: { message?: string | string[] }) {
  const text = Array.isArray(message) ? message[0] : message;
  if (!text) return null;

  return (
    <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
      {text}
    </p>
  );
}
