import { createAppRouter } from "./libraries/router/createAppRouter";
import { searchIndex } from "./nav.generated";
import App from "./frameworks/react/App";
import HomeView from "./frameworks/react/views/HomeView";
import DocPage from "./frameworks/react/views/DocPage";
import DashboardRequirementsView from "./frameworks/react/views/DashboardRequirementsView";
import DashboardView from "./frameworks/react/views/DashboardView";
import RunHistoryView from "./frameworks/react/views/RunHistoryView";
import CiStatusView from "./frameworks/react/views/CiStatusView";
import PlaytestNotesView from "./frameworks/react/views/PlaytestNotesView";
import LoreMapView from "./frameworks/react/views/LoreMapView";
import UnitVisualizerView from "./frameworks/react/views/UnitVisualizerView";

const router = createAppRouter({
  routes: [
    {
      path: "/",
      element: <App />,
      children: [
        { index: true, element: <HomeView /> },
        { path: "dashboard",                    element: <DashboardView /> },
        { path: "dashboard/runs",               element: <RunHistoryView /> },
        { path: "dashboard/ci",                 element: <CiStatusView /> },
        { path: "dashboard/playtest",           element: <PlaytestNotesView /> },
        { path: "dashboard/lore-map",           element: <LoreMapView /> },
        { path: "dashboard/visualizer",         element: <UnitVisualizerView /> },
        { path: "dashboard/requirements",       element: <DashboardRequirementsView /> },
        { path: "*",                            element: <DocPage /> },
      ],
    },
  ],
});

export function findPageBySource(source: string) {
  return searchIndex.find((p) => p.source === source);
}

export default router;
