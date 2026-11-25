cd "$(dirname "$0")"
bun test src/ > /dev/null 2>&1 || { echo "FAIL: bun test"; exit 1; }

cat > .hidden_edge.test.ts <<'EOF'
import { test, expect } from "bun:test";
import { parsePagination, ParseError } from "./src/query";

test("non-numeric page throws ParseError", () => {
  expect(() => parsePagination({ page: "abc" })).toThrow(ParseError);
});
test("non-numeric limit throws ParseError", () => {
  expect(() => parsePagination({ limit: "x" })).toThrow(ParseError);
});
test("negative limit throws ParseError", () => {
  expect(() => parsePagination({ limit: "-5" })).toThrow(ParseError);
});
test("zero page throws ParseError", () => {
  expect(() => parsePagination({ page: "0" })).toThrow(ParseError);
});
test("empty string throws ParseError", () => {
  expect(() => parsePagination({ page: "" })).toThrow(ParseError);
});
EOF
bun test .hidden_edge.test.ts > /dev/null 2>&1 || { echo "FAIL: edge cases"; rm -f .hidden_edge.test.ts; exit 1; }
rm -f .hidden_edge.test.ts
exit 0
