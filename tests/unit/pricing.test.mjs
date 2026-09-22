import test from "node:test";
import assert from "node:assert/strict";
import { calculateInvoice, resolvePrice } from "../../lib/domain/pricing.mjs";
test("price precedence preserves an explicit zero", () => { assert.deepEqual(resolvePrice({globalAmount:39900,masterAmount:35000,siteAmount:0}),{amount:0,source:"site"}); assert.deepEqual(resolvePrice({globalAmount:39900,masterAmount:0}),{amount:0,source:"master"}); });
test("invoice rolls enabled module charges into site-owned lines",()=>{ const invoice=calculateInvoice([{id:"a",base:39900,modules:[{key:"fuel",enabled:true,amount:1200},{key:"pos",enabled:false,amount:900}]},{id:"b",base:35000,modules:[],adjustments:[{kind:"credit",amount:-500}]}]); assert.equal(invoice.total,75600); assert.equal(invoice.lines.length,4); assert.ok(invoice.lines.every(line=>line.siteId)); });
test("money rejects fractional cents",()=>assert.throws(()=>resolvePrice({globalAmount:1.2}),/integer cents/));
