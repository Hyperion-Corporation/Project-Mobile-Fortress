import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { defineComponent, nextTick } from 'vue';
import { directivesPlugin } from '../../../src/frameworks/vue/directives';

describe('custom Vue directives', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('v-click-outside invokes handler for outside clicks and skips inside', async () => {
    const onOutside = vi.fn();
    const Comp = defineComponent({
      template: `<div class="host" v-click-outside="onOutside"><button class="inner">in</button></div>`,
      methods: { onOutside },
    });
    const wrapper = mount(Comp, {
      global: { plugins: [directivesPlugin] },
      attachTo: document.body,
    });

    wrapper.find('.inner').element.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    expect(onOutside).not.toHaveBeenCalled();

    document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    // capture-phase listener on document
    expect(onOutside).toHaveBeenCalledTimes(1);

    wrapper.unmount();
  });

  it('v-focus focuses the host when the binding is truthy', async () => {
    const Comp = defineComponent({
      props: { shouldFocus: { type: Boolean, default: true } },
      template: `<input data-testid="field" v-focus="shouldFocus" />`,
    });
    const wrapper = mount(Comp, {
      props: { shouldFocus: true },
      global: { plugins: [directivesPlugin] },
      attachTo: document.body,
    });

    await nextTick();
    await Promise.resolve(); // queueMicrotask from directive
    expect(document.activeElement).toBe(wrapper.get('[data-testid="field"]').element);

    wrapper.unmount();
  });

  it('v-intersect observes the element when IntersectionObserver exists', async () => {
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

    const Comp = defineComponent({
      template: `<div class="target" v-intersect="onVisible" />`,
      methods: { onVisible: handler },
    });
    const wrapper = mount(Comp, {
      global: { plugins: [directivesPlugin] },
      attachTo: document.body,
    });

    expect(observe).toHaveBeenCalled();
    wrapper.unmount();
    expect(disconnect).toHaveBeenCalled();
  });
});
