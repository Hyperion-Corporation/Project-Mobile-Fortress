import { afterAll, afterEach, beforeAll, beforeEach } from 'vitest';
import { server } from './integration/mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Node's own built-in `localStorage` can shadow jsdom's; use an in-memory store.
class MemoryStorage implements Storage {
  private store = new Map<string, string>();

  get length(): number {
    return this.store.size;
  }

  clear(): void {
    this.store.clear();
  }

  getItem(key: string): string | null {
    return this.store.has(key) ? this.store.get(key)! : null;
  }

  key(index: number): string | null {
    return Array.from(this.store.keys())[index] ?? null;
  }

  removeItem(key: string): void {
    this.store.delete(key);
  }

  setItem(key: string, value: string): void {
    this.store.set(key, String(value));
  }
}

const memoryStorage = new MemoryStorage();
Object.defineProperty(window, 'localStorage', { value: memoryStorage, writable: true });
Object.defineProperty(globalThis, 'localStorage', { value: memoryStorage, writable: true });

beforeEach(() => memoryStorage.clear());
