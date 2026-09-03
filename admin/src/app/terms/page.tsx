import type { Metadata } from "next";
import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Terms of use — Dahr",
  description: "Terms of use for the Dahr wedding marketplace (Libya).",
};

export default function TermsRoute() {
  return <LegalPage kind="terms" />;
}
