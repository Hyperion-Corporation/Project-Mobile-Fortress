import { fireEvent, render, screen, cleanup } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import CitadelRankWidget from "../../../src/frameworks/react/components/CitadelRankWidget";
import { parsePrestigeTiers } from "../../../src/simulations/citadelRank";
import source from "../../../../../game/scripts/data/progression.gd?raw";

const tiers = parsePrestigeTiers(source);
afterEach(cleanup);
describe("citadel rank controls", () => {
  it("keeps exact below-threshold values in both controls", () => {
    render(<CitadelRankWidget tiers={tiers} />);
    fireEvent.change(screen.getByRole("spinbutton"), { target: { value: "749" } });
    const slider = screen.getByRole("slider") as HTMLInputElement;
    expect(slider.step).toBe("1");
    expect(slider.value).toBe("749");
    expect(screen.getByTestId("crw-rank-badge").textContent).toContain("Sentry Bastion");
    expect(screen.getByTestId("crw-remaining").textContent).toBe("1 prestige needed");
    fireEvent.change(slider, { target: { value: "750" } });
    expect((screen.getByRole("spinbutton") as HTMLInputElement).value).toBe("750");
    expect(screen.getByTestId("crw-rank-badge").textContent).toContain("Garrison Fortress");
  });
  it("shows max rank above the slider ceiling without an out-of-range slider value", () => {
    render(<CitadelRankWidget tiers={tiers} />);
    fireEvent.change(screen.getByRole("spinbutton"), { target: { value: "99999" } });
    expect(screen.getByText(/Max rank reached/)).toBeDefined();
    expect((screen.getByRole("slider") as HTMLInputElement).value).toBe("5000");
    expect(screen.queryByRole("progressbar")).toBeNull();
  });
  it("normalizes numeric input including exponent notation and lower bound", () => {
    render(<CitadelRankWidget tiers={tiers} />);
    fireEvent.change(screen.getByRole("spinbutton"), { target: { value: "1e3" } });
    expect(screen.getByTestId("crw-prestige-value").textContent).toBe("1000");
    fireEvent.change(screen.getByRole("spinbutton"), { target: { value: "-1" } });
    expect(screen.getByTestId("crw-prestige-value").textContent).toBe("0");
  });
});
