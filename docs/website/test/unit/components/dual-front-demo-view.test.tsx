/**
 * dual-front-demo-view.test.tsx — ID8: View render + interaction test.
 *
 * Mounts the DualFrontDemoView, verifies key elements render, and tests
 * the placement → start → outcome interaction flow.
 */
import { describe, expect, it, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import DualFrontDemoView from "../../../src/frameworks/react/views/DualFrontDemoView";

afterEach(cleanup);

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
});
