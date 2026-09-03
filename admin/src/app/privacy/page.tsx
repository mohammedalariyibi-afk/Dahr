import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Privacy policy — Dahr",
  description: "Privacy policy for the Dahr wedding marketplace (Libya).",
};

export default function PrivacyRoute() {
  return <LegalPage kind="privacy" />;
}
