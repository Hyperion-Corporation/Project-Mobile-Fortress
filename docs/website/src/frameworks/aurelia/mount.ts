// Mounts the Aurelia 2 island into a plain DOM node — the same pattern any
// non-primary framework in this site uses (see frameworks/react's
// ReactDOM.createRoot() usage), just with Aurelia's own Aurelia.app().start().
import { Aurelia } from "aurelia";
import { ConvergenceChartApp } from "./convergence-chart-app";
import { logIslandMount, logIslandUnmount } from "../shared/utils";

export interface AureliaMountHandle {
  stop(): Promise<void>;
}

export function mountConvergenceChart(host: HTMLElement): AureliaMountHandle {
  const au = new Aurelia();
  au.app({ host, component: ConvergenceChartApp });
  void au.start();
  logIslandMount("Aurelia", "convergence-chart");

  return {
    async stop() {
      await au.stop(true);
      logIslandUnmount("Aurelia", "convergence-chart");
    },
  };
}
