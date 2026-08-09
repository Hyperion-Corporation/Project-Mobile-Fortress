import { describe, expect, it, vi } from 'vitest';
import { apolloClient } from '../../../src/frameworks/apollo/client';
import { OUTPOSTS_QUERY } from '../../../src/frameworks/apollo/queries';
import * as dataModule from '../../../src/frameworks/apollo/data';

// MFP15 — per-island test matrix, "cache broadcast" row. client.ts's local
// ApolloLink resolves Query fields by calling into data.ts's plain
// getOutposts()/getRaidLanes()/etc — proves the shared InMemoryCache (not
// the link) serves a second read of the same entity, the same guarantee a
// live GraphQL server + normalized cache gives multiple `useQuery` call
// sites (e.g. two ApolloLorePanel instances) reading the same data.
describe('Apollo island — InMemoryCache broadcast (MFP15)', () => {
  it('serves a second query for the same data from cache, not the local resolver again', async () => {
    const getOutpostsSpy = vi.spyOn(dataModule, 'getOutposts');

    const first = await apolloClient.query({ query: OUTPOSTS_QUERY, fetchPolicy: 'cache-first' });
    expect(getOutpostsSpy).toHaveBeenCalledTimes(1);
    expect(first.data.outposts.length).toBeGreaterThan(0);

    const second = await apolloClient.query({ query: OUTPOSTS_QUERY, fetchPolicy: 'cache-first' });
    // Still 1 — the second call site read the InMemoryCache, it didn't
    // re-invoke the local resolver (the same behavior a real network
    // round-trip would skip on a cache hit).
    expect(getOutpostsSpy).toHaveBeenCalledTimes(1);
    expect(second.data).toEqual(first.data);

    getOutpostsSpy.mockRestore();
  });
});
