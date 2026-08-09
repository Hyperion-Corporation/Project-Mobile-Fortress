// Aurelia 2 custom element — no separate .html template file (this package
// has no aurelia-loader/vite-plugin-aurelia wired up), so the template is
// defined inline via the static `$au` resource-definition option, the same
// mechanism Aurelia's own `au.app()` bootstrapping resolves for the root
// component either way.
//
// Deliberately NOT using the `@customElement`/`@bindable` decorators here:
// Aurelia 2's decorator-based resource metadata is stored on the class via
// the TC39 stage-3 decorator-metadata proposal (`Symbol.metadata` — see
// @aurelia/metadata's `Metadata.get/define`), which only gets populated by
// *modern* (non-legacy) decorator output. Vite/esbuild happens to emit
// modern decorators by default, but Next's SWC only supports legacy
// decorators and ties decorator *parsing* itself to
// `tsconfig.compilerOptions.experimentalDecorators` (on = legacy parse+
// transform, off = doesn't parse `@` syntax at all) — there's no tsconfig
// combination that gets modern semantics out of it. The static `$au`
// property below is Aurelia's own documented decorator-free equivalent
// (see `getDefinitionFromStaticAu` in @aurelia/runtime-html): plain data,
// no decorator transform involved, so it behaves identically under every
// bundler this site uses (Vite and stack/next/'s webpack).
import { createSimulationController, type SimulationController } from "../../simulations/context/createSimulationController";
import { SIMULATION_SCENARIOS } from "../../simulations/scenarios/scenarios";
import type { SimulationSample } from "../../simulations/repository/types";

const WIDTH = 100;
const HEIGHT = 48;

function toPoints(samples: SimulationSample[], revealCount: number): string {
  if (samples.length === 0) return "";
  const maxCost = Math.max(...samples.map((s) => s.cost));
  const minCost = Math.min(...samples.map((s) => s.cost));
  const range = Math.max(1, maxCost - minCost);
  return samples
    .slice(0, revealCount)
    .map((s, i) => {
      const x = (i / Math.max(1, samples.length - 1)) * WIDTH;
      const y = HEIGHT - ((s.cost - minCost) / range) * HEIGHT;
      return `${x.toFixed(2)},${y.toFixed(2)}`;
    })
    .join(" ");
}

const template = `
<div class="cc-root">
  <header>
    <p class="kicker">Framework island · Aurelia 2</p>
    <h2>HQ-layout GA convergence (src/simulations/)</h2>
    <p class="subtitle">\${scenario.description}</p>
  </header>

  <div class="controls">
    <select change.trigger="onScenarioChange($event.target)">
      <option repeat.for="s of scenarioList" model.bind="s.id" selected.bind="s.id === scenario.id">\${s.name}</option>
    </select>
    <button type="button" click.trigger="rerun()">Re-run (new seed)</button>
    <span class="step-label">iteration \${revealCount} / \${samples.length} · cost \${currentCost}</span>
  </div>

  <svg viewBox="0 0 100 48" preserveAspectRatio="none" role="img" aria-label="GA convergence cost curve">
    <!-- SVGPolylineElement.points is a getter-only DOM IDL property (an
         SVGPointList), so the default property.bind heuristic's plain
         assignment throws — .attr forces Aurelia's attribute-binding
         command (setAttribute) instead. -->
    <polyline points.attr="pointsAttr" fill="none" stroke="currentColor" stroke-width="1.4"></polyline>
  </svg>
</div>
`;

export class ConvergenceChartApp {
  static $au = {
    type: "custom-element",
    name: "convergence-chart",
    template,
    bindables: ["autoplay"],
  };

  autoplay = true;

  scenarioList = SIMULATION_SCENARIOS;
  scenario = SIMULATION_SCENARIOS[0];
  controller: SimulationController = createSimulationController(this.scenario.id);
  samples: SimulationSample[] = [];
  revealCount = 0;
  private timer: ReturnType<typeof setInterval> | null = null;

  get pointsAttr(): string {
    return toPoints(this.samples, this.revealCount);
  }

  get currentCost(): number | string {
    const sample = this.samples[Math.max(0, this.revealCount - 1)];
    return sample ? sample.cost : "—";
  }

  binding() {
    this.samples = this.controller.run.samples;
    if (this.autoplay) this.play();
    else this.revealCount = this.samples.length;
  }

  play() {
    this.revealCount = 0;
    if (this.timer) clearInterval(this.timer);
    this.timer = setInterval(() => {
      this.revealCount++;
      if (this.revealCount >= this.samples.length) {
        this.stop();
      }
    }, 90);
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  rerun() {
    this.samples = this.controller.rerun(Date.now() % 100000).samples;
    this.play();
  }

  onScenarioChange(target: HTMLSelectElement) {
    const next = this.scenarioList.find((s) => s.id === target?.value);
    if (!next) return;
    this.scenario = next;
    this.controller = createSimulationController(next.id);
    this.samples = this.controller.run.samples;
    this.play();
  }

  unbinding() {
    this.stop();
  }
}
