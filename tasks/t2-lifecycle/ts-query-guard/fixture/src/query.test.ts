import { test, expect } from "bun:test";
import { parsePagination } from "./query";

test("defaults", () => {
  expect(parsePagination({})).toEqual({ page: 1, limit: 20 });
});

test("valid values pass through", () => {
  expect(parsePagination({ page: "3", limit: "50" })).toEqual({ page: 3, limit: 50 });
});
