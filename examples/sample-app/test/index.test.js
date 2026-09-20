import { test } from "node:test";
import assert from "node:assert/strict";
import { greet } from "../src/index.js";

test("greets the given name", () => {
  assert.equal(greet("Codex"), "Hello, Codex! This is the multi-agent-coding-kit sample app.");
});

test("throws without a name", () => {
  assert.throws(() => greet(), /name is required/);
});
