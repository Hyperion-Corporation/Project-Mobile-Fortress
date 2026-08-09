import { http, HttpResponse } from 'msw';

/** MSW handlers for integration tests. Extend as website APIs appear. */
export const handlers = [
  http.get('/api/health', () => HttpResponse.json({ ok: true })),
];
