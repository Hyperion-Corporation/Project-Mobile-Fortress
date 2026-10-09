import { fireEvent, render, screen, cleanup, act } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { MemoryRouter } from "react-router-dom";
import CosmeticAuditView from "../../../src/frameworks/react/views/CosmeticAuditView";

afterEach(cleanup);

describe("CosmeticAuditView Component Tests (M2 / Q9)", () => {
  it("renders transparency header, compliance badges, and table", () => {
    render(
      <MemoryRouter>
        <CosmeticAuditView />
      </MemoryRouter>
    );

    expect(screen.getByText(/Cosmetic Probability & Audit/i)).toBeDefined();
    expect(screen.getByText(/Strict Anti-P2W/i)).toBeDefined();
    expect(screen.getByText(/Kompu-Gacha Compliant/i)).toBeDefined();
    expect(screen.getByText(/Disclosed Rarity & Drop Rates/i)).toBeDefined();

    // Verify disclosure rates in table
    expect(screen.getByText("60.00%")).toBeDefined();
    expect(screen.getByText("27.00%")).toBeDefined();
    expect(screen.getByText("10.00%")).toBeDefined();
    expect(screen.getByText("3.00%")).toBeDefined();
  });

  it("handles pull simulation and advances counters", () => {
    render(
      <MemoryRouter>
        <CosmeticAuditView />
      </MemoryRouter>
    );

    const pull1Btn = screen.getByRole("button", { name: /Open 1 Box/i });
    fireEvent.click(pull1Btn);

    expect(screen.getByText(/Total Pulls:/i).textContent).toContain("1");

    const pull10Btn = screen.getByRole("button", { name: /Open 10 Boxes/i });
    fireEvent.click(pull10Btn);

    expect(screen.getByText(/Total Pulls:/i).textContent).toContain("11");
  });

  it("filters catalog items by rarity tabs", () => {
    render(
      <MemoryRouter>
        <CosmeticAuditView />
      </MemoryRouter>
    );

    const legendaryTab = screen.getByRole("button", { name: "legendary" });
    fireEvent.click(legendaryTab);

    // Only 3 legendary items should show
    expect(screen.getByText("Great General of the Southern Seas")).toBeDefined();
    expect(screen.getByText("Viceroy of Goa Ceremonial Regalia")).toBeDefined();
    expect(screen.getByText("Indomitable Granite Citadel")).toBeDefined();
    expect(screen.queryByText("Bamboo Militia Banner")).toBeNull();
  });

  it("executes Monte Carlo statistical audit and displays pass verdict", async () => {
    render(
      <MemoryRouter>
        <CosmeticAuditView />
      </MemoryRouter>
    );

    const auditBtn = screen.getByRole("button", { name: /Run Monte Carlo Audit/i });
    act(() => {
      fireEvent.click(auditBtn);
    });

    // Wait for setTimeout in audit
    await act(async () => {
      await new Promise((r) => setTimeout(r, 100));
    });

    expect(screen.getByText(/PASS \(COMPLIANT\)/i)).toBeDefined();
    expect(screen.getByText(/Common Observed/i)).toBeDefined();
  });
});
