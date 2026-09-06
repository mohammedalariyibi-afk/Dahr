## 2025-05-18 - Navigation landmarks and badge accessibility

**Learning:** Navigation bars in Next.js admin layouts require explicit `aria-label` landmarks, `aria-current="page"` on active links, and screen-reader accessible context (`sr-only`) on numerical badges (e.g. pending vendor count) so assistive technology users understand both page position and badge meaning.
**Action:** Always add `aria-label` to `<nav>`, `aria-current={active ? "page" : undefined}` on current route links, and `sr-only` descriptions for status/count badges.
