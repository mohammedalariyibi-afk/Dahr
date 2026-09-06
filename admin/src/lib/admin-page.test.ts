import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { sumUnpaidCommission } from "./admin-aggregates";
import {
  ADMIN_PAGE_SIZE,
  clampPage,
  lastPage,
  pageHrefs,
  pageRange,
  parsePage,
  showingRange,
  withSearchParams,
} from "./admin-page";
import { sanitizeAdminSearch, vendorSearchOr } from "./vendor-search";

describe("admin pagination", () => {
  it("parses and clamps page numbers", () => {
    assert.equal(parsePage(undefined), 1);
    assert.equal(parsePage("0"), 1);
    assert.equal(parsePage("-2"), 1);
    assert.equal(parsePage("3"), 3);
    assert.equal(lastPage(0), 1);
    assert.equal(lastPage(50), 1);
    assert.equal(lastPage(51), 2);
    assert.equal(clampPage(9, 120), 3);
  });

  it("uses inclusive PostgREST ranges under the 1000-row cap", () => {
    assert.deepEqual(pageRange(1), { from: 0, to: 49 });
    assert.deepEqual(pageRange(2), { from: 50, to: 99 });
    assert.ok(ADMIN_PAGE_SIZE <= 100);
    assert.ok(pageRange(20).to < 1000);
  });

  it("reports an honest showing range", () => {
    assert.deepEqual(showingRange(1, 12), { from: 1, to: 12 });
    assert.deepEqual(showingRange(2, 120), { from: 51, to: 100 });
    assert.deepEqual(showingRange(1, 0), { from: 0, to: 0 });
  });

  it("builds page links without carrying error codes", () => {
    const params = new URLSearchParams("filter=pending&error=write_failed");
    assert.equal(
      withSearchParams("/vendors", params, { page: "2" }),
      "/vendors?filter=pending&page=2",
    );
    assert.equal(
      withSearchParams("/vendors", params, { page: null, filter: null }),
      "/vendors",
    );
    const hrefs = pageHrefs("/reports", new URLSearchParams("status=all"), 2, 120);
    assert.equal(hrefs.prevHref, "/reports?status=all");
    assert.equal(hrefs.nextHref, "/reports?status=all&page=3");
  });
});

describe("vendor search", () => {
  it("strips PostgREST or() metacharacters and keeps Arabic", () => {
    assert.equal(sanitizeAdminSearch("hall,or=(id.eq.1)"), "hall or id eq 1");
    assert.equal(sanitizeAdminSearch("%foo_"), "foo");
    assert.equal(sanitizeAdminSearch("قاعة 12"), "قاعة 12");
  });

  it("builds SQL-side or filters including owner profile ids", () => {
    const clause = vendorSearchOr("photo", ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"]);
    assert.ok(clause);
    assert.match(clause, /business_name\.ilike\.%photo%/);
    assert.match(clause, /category\.eq\.photography/);
    assert.match(clause, /profile_id\.in\.\(aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\)/);
    assert.equal(vendorSearchOr(""), null);
  });
});

describe("sumUnpaidCommission", () => {
  it("uses the PostgREST aggregate row when present", async () => {
    const supabase = {
      from() {
        return {
          select() {
            return {
              eq() {
                return {
                  maybeSingle: async () => ({
                    data: { total: "1234.50" },
                    error: null,
                  }),
                };
              },
            };
          },
        };
      },
    };
    const result = await sumUnpaidCommission(
      supabase as unknown as Parameters<typeof sumUnpaidCommission>[0],
    );
    assert.equal(result.sum, 1234.5);
    assert.equal(result.error, null);
  });

  it("pages amount-only rows when sum() is disabled", async () => {
    let rangeCalls = 0;
    const supabase = {
      from() {
        return {
          select(columns: string) {
            if (columns.includes("sum()")) {
              return {
                eq() {
                  return {
                    maybeSingle: async () => ({
                      data: null,
                      error: { message: "aggregates disabled" },
                    }),
                  };
                },
              };
            }
            return {
              eq() {
                return {
                  range: async () => {
                    rangeCalls += 1;
                    return {
                      data: [{ commission_amount_lyd: "10" }, { commission_amount_lyd: "2.5" }],
                      error: null,
                    };
                  },
                };
              },
            };
          },
        };
      },
    };
    const result = await sumUnpaidCommission(
      supabase as unknown as Parameters<typeof sumUnpaidCommission>[0],
    );
    assert.equal(result.sum, 12.5);
    assert.equal(result.error, null);
    assert.equal(rangeCalls, 1);
  });
});
