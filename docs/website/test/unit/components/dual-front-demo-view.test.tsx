/**
 * dual-front-demo-view.test.tsx — ID8: View render + interaction test.
 *
 * Mounts the DualFrontDemoView, verifies key elements render, and tests
 * the placement → start → outcome interaction flow.
 */
import { describe, expect, it, afterEach, vi } from "vitest";
import { render, screen, cleanup, fireEvent, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import DualFrontDemoView from "../../../src/frameworks/react/views/DualFrontDemoView";

afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

function renderView() {
  return render(
    <MemoryRouter initialEntries={["/dashboard/demo"]}>
      <DualFrontDemoView />
    </MemoryRouter>,
  );
}

describe("DualFrontDemoView", () => {
  it("renders the header and placement phase label", () => {
    renderView();
    expect(screen.getByText("⚔️ Dual-Front Demo")).toBeDefined();
    expect(screen.getByText("🔨 Placement Phase")).toBeDefined();
  });

  it("renders both front grids", () => {
    renderView();
    expect(screen.getByText("🟫 Land Front")).toBeDefined();
    expect(screen.getByText("🌊 Sea Front")).toBeDefined();
  });

  it("renders unit selection buttons in placement phase", () => {
    renderView();
    expect(screen.getByText(/Spearman/)).toBeDefined();
    expect(screen.getByText(/Crew/)).toBeDefined();
    expect(screen.getByText(/Arquebusier/)).toBeDefined();
    expect(screen.getByText(/Junk/)).toBeDefined();
  });

  it("renders the Start Raid button", () => {
    renderView();
    const buttons = screen.getAllByText("▶ Start Raid");
    expect(buttons.length).toBeGreaterThanOrEqual(1);
    expect(buttons[0].tagName).toBe("BUTTON");
  });

  it("renders budget display", () => {
    renderView();
    expect(screen.getByText(/Land 兩/)).toBeDefined();
    expect(screen.getByText(/Sea 兩/)).toBeDefined();
  });

  it("renders the how-to-play instructions", () => {
    renderView();
    expect(screen.getByText("How to play")).toBeDefined();
  });

  it("renders navigation links", () => {
    renderView();
    expect(screen.getByText("⚔️ Demo")).toBeDefined();
  });

  it("module can be imported", async () => {
    const mod = await import("../../../src/frameworks/react/views/DualFrontDemoView");
    expect(typeof mod.default).toBe("function");
  });

  it("renders hero and cross-support unit buttons", () => {
    renderView();
    expect(screen.getByText(/\(Hero\) ⭐/)).toBeDefined();
    expect(screen.getAllByText(/Battery/).length).toBeGreaterThanOrEqual(1);
  });

  it("renders hero badge on the hero unit button", () => {
    renderView();
    const heroBtn = screen.getByRole("button", { name: /\(Hero\)/ });
    expect(heroBtn.textContent).toContain("⭐");
  });

  it("renders cross-support badge on the cross-support button", () => {
    renderView();
    const crossBtn = screen.getByRole("button", { name: /Battery/ });
    expect(crossBtn.textContent).toContain("🔗");
  });

  it("enables cross-support when land is exhausted but sea can afford it", () => {
    renderView();
    const cell = (front: string, row: number, col: number) => screen.getByRole("button", {
      name: new RegExp(`^${front} grid, column ${col + 1}, row ${row + 1}`),
    });
    fireEvent.click(screen.getByRole("button", { name: /Spearman/ }));
    for (let c = 0; c < 6; c++) {
      fireEvent.click(cell("land", 0, c));
    }
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("0");
    const batteryBtn = screen.getByRole("button", { name: /Battery/ });
    expect(batteryBtn.getAttribute("disabled")).toBeNull();
    fireEvent.click(batteryBtn);
    // An empty land cell remains unaffordable; the sea wallet must not fund it.
    fireEvent.click(cell("land", 2, 0));
    expect(cell("land", 2, 0).getAttribute("aria-label")).not.toContain("Signal Battery");
    expect(screen.getByText(/Sea 兩/).querySelector("strong")?.textContent).toBe("60");
    fireEvent.click(cell("sea", 0, 0));
    expect(cell("sea", 0, 0).getAttribute("aria-label")).toContain("Signal Battery");
    expect(screen.getByText(/Sea 兩/).querySelector("strong")?.textContent).toBe("40");
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("0");
  });
});

describe("demo interactions", () => {
  it("places and refunds units, runs to victory, and resets both budgets", () => {
    vi.useFakeTimers();
    renderView();
    const cell = (front: string, row: number) => screen.getByRole("button", {
      name: new RegExp(`^${front} grid, column 3, row ${row}`),
    });
    fireEvent.click(cell("land", 1));
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("50");
    expect(cell("land", 1).getAttribute("aria-label")).toContain("Spearman");
    fireEvent.click(cell("land", 1));
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("60");
    fireEvent.click(screen.getByRole("button", { name: /Crew/ }));
    fireEvent.click(cell("land", 1));
    fireEvent.click(cell("land", 3));
    fireEvent.click(screen.getByRole("button", { name: /Junk/ }));
    fireEvent.click(cell("sea", 1));
    fireEvent.click(cell("sea", 3));
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("24");
    expect(screen.getByText(/Sea 兩/).querySelector("strong")?.textContent).toBe("28");
    fireEvent.click(screen.getByRole("button", { name: /Start Raid/ }));
    expect(screen.getByText("⚔️ Combat")).toBeDefined();
    fireEvent.click(screen.getByRole("button", { name: /Skip/ }));
    expect(screen.getByRole("status").textContent).toContain("Victory!");
    expect(vi.getTimerCount()).toBe(0);
    fireEvent.click(screen.getByRole("button", { name: /Play Again/ }));
    expect(screen.getByText(/Land 兩/).querySelector("strong")?.textContent).toBe("60");
    expect(screen.getByText(/Sea 兩/).querySelector("strong")?.textContent).toBe("60");
    expect(cell("land", 1).getAttribute("aria-label")).not.toContain("Crew");
  });

  it("renders moving raiders only on the path and stops the timer on defeat", () => {
    vi.useFakeTimers();
    renderView();
    fireEvent.click(screen.getByRole("button", { name: /Start Raid/ }));
    act(() => vi.advanceTimersByTime(800));
    const raiders = screen.getAllByRole("button", { name: /, raider, HP/ });
    expect(raiders).toHaveLength(2);
    for (const raider of raiders) expect(raider.getAttribute("aria-label")).toContain("row 2");
    act(() => vi.advanceTimersByTime(20000));
    expect(screen.getByRole("status").textContent).toContain("Defeat");
    expect(vi.getTimerCount()).toBe(0);
  });

  it("cleans up a running timer on unmount", () => {
    vi.useFakeTimers();
    const view = renderView();
    fireEvent.click(screen.getByRole("button", { name: /Start Raid/ }));
    expect(vi.getTimerCount()).toBe(1);
    view.unmount();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("resolves combat without an animation timer for reduced motion", () => {
    vi.useFakeTimers();
    vi.stubGlobal("matchMedia", vi.fn(() => ({
      matches: true,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    })));
    renderView();
    fireEvent.click(screen.getByRole("button", { name: /Start Raid/ }));
    expect(screen.getByRole("status").textContent).toContain("Defeat");
    expect(vi.getTimerCount()).toBe(0);
  });
});
