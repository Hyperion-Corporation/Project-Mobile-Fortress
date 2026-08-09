import { useEffect, useRef } from "react";
import type { AureliaMountHandle } from "./mount";
import "./ConvergenceChartWrapper.css";

export default function ConvergenceChartWrapper() {
  const hostRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!hostRef.current) return;
    let handle: AureliaMountHandle | null = null;
    let cancelled = false;

    import("./mount").then(({ mountConvergenceChart }) => {
      if (cancelled || !hostRef.current) return;
      handle = mountConvergenceChart(hostRef.current);
    });

    return () => {
      cancelled = true;
      void handle?.stop();
    };
  }, []);

  return (
    <section className="aurelia-island-wrap panel">
      <div ref={hostRef} className="aurelia-host" />
    </section>
  );
}
