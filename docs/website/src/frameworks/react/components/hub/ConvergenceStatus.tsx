import { useState } from "react";
import { createSimulationController } from "../../../../simulations/context/createSimulationController";
import { convergenceSummary } from "../../../../simulations/summary";
import "./ConvergenceStatus.css";

/**
 * MFP7 — cross-framework parity kit: the React half of the pair. Runs the
 * same `src/simulations/` GA-convergence controller the Aurelia island
 * (`convergence-chart-app.ts`) visualizes, and renders the identical
 * `convergenceSummary()` text in a matching `role="status"` region — proof
 * that two independently-rendered frameworks can present the same
 * underlying data with consistent accessible semantics. See
 * ConvergenceChartWrapper (Aurelia) for the counterpart.
 */
export default function ConvergenceStatus() {
  const [summary] = useState(() => {
    const controller = createSimulationController();
    return convergenceSummary(controller.run.samples, controller.run.samples.length);
  });

  return (
    <p className="convergence-status" role="status" aria-live="polite">
      <strong>React:</strong> {summary}
    </p>
  );
}
