import { createAppRouter } from "./libraries/router/createAppRouter";
import { searchIndex } from "./nav.generated";
import App from "./frameworks/react/App";
import HomeView from "./frameworks/react/views/HomeView";
import DocPage from "./frameworks/react/views/DocPage";

const router = createAppRouter({
  routes: [
    {
      path: "/",
      element: <App />,
      children: [
        { index: true, element: <HomeView /> },
        { path: "*", element: <DocPage /> },
      ],
    },
  ],
});

export function findPageBySource(source: string) {
  return searchIndex.find((p) => p.source === source);
}

export default router;
