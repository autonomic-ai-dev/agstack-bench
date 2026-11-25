export interface Pagination {
  page: number;
  limit: number;
}

export class ParseError extends Error {}

export function parsePagination(query: Record<string, string>): Pagination {
  const page = parseInt(query.page ?? "1", 10);
  const limit = parseInt(query.limit ?? "20", 10);
  const clamped = Math.min(limit, 100);
  return { page, limit: clamped };
}
