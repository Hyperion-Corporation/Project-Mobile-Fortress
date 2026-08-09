import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, cleanup, act } from '@testing-library/react';
import { useRef, type RefObject } from 'react';
import { useClickOutside } from '../../../src/hooks/useClickOutside';
import { useFocusWhen } from '../../../src/hooks/useFocusWhen';
import { useIntersect } from '../../../src/hooks/useIntersect';

describe('custom React shell hooks', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    cleanup();
  });

  it('useClickOutside invokes handler for outside clicks and skips inside', () => {
    const onOutside = vi.fn();

    function Host() {
      const ref = useRef<HTMLDivElement | null>(null);
      useClickOutside(ref, onOutside);
      return (
        <div ref={ref} className="host">
          <button className="inner">in</button>
        </div>
      );
    }

    render(<Host />);

    fireEvent.click(screen.getByText('in'));
    expect(onOutside).not.toHaveBeenCalled();

    fireEvent.click(document.body);
    expect(onOutside).toHaveBeenCalledTimes(1);
  });

  it('useFocusWhen focuses the host when active is true', async () => {
    function Host({ active }: { active: boolean }) {
      const ref = useRef<HTMLInputElement | null>(null);
      useFocusWhen(ref, active);
      return <input data-testid="field" ref={ref} />;
    }

    render(<Host active />);
    await act(async () => {
      await Promise.resolve();
    });
    expect(document.activeElement).toBe(screen.getByTestId('field'));
  });

  it('useIntersect observes the element when IntersectionObserver exists', () => {
    const handler = vi.fn();
    const observe = vi.fn();
    const disconnect = vi.fn();
    const unobserve = vi.fn();

    class FakeIO {
      constructor(
        public cb: IntersectionObserverCallback,
        public options?: IntersectionObserverInit
      ) {}
      observe = observe;
      unobserve = unobserve;
      disconnect = disconnect;
      takeRecords = () => [];
      root = null;
      rootMargin = '';
      thresholds = [];
    }

    // @ts-expect-error test shim
    globalThis.IntersectionObserver = FakeIO;

    function Host() {
      const ref = useRef<HTMLDivElement | null>(null) as RefObject<HTMLDivElement | null>;
      useIntersect(ref, handler);
      return <div className="target" ref={ref} />;
    }

    const { unmount } = render(<Host />);
    expect(observe).toHaveBeenCalled();
    unmount();
    expect(disconnect).toHaveBeenCalled();
  });
});
