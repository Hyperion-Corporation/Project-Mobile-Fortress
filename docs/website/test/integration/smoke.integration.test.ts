import { describe, expect, it } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from './mocks/server';

describe('integration smoke', () => {
  it('serves the health fixture via MSW', async () => {
    server.use(
      http.get('/api/health', () => HttpResponse.json({ ok: true, service: 'docs-website' }))
    );
    const res = await fetch('/api/health');
    const body = (await res.json()) as { ok: boolean; service?: string };
    expect(res.ok).toBe(true);
    expect(body.ok).toBe(true);
  });
});
