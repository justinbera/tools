/** Resolve a nullable override chain without confusing an explicit zero with absence. */
export function resolvePrice({ globalAmount, masterAmount = null, siteAmount = null }) {
  if (!Number.isSafeInteger(globalAmount) || globalAmount < 0) throw new Error("Global price must be non-negative integer cents");
  for (const value of [masterAmount, siteAmount]) if (value !== null && (!Number.isSafeInteger(value) || value < 0)) throw new Error("Overrides must be null or non-negative integer cents");
  if (siteAmount !== null) return { amount: siteAmount, source: "site" };
  if (masterAmount !== null) return { amount: masterAmount, source: "master" };
  return { amount: globalAmount, source: "global" };
}

export function calculateInvoice(sites) {
  const lines = sites.flatMap((site) => [{ siteId: site.id, kind: "base", amount: site.base }, ...site.modules.filter((m) => m.enabled).map((m) => ({ siteId: site.id, kind: `module:${m.key}`, amount: m.amount })), ...(site.adjustments ?? []).map((a) => ({ siteId: site.id, kind: a.kind, amount: a.amount }))]);
  return { lines, total: lines.reduce((sum, line) => sum + line.amount, 0) };
}
