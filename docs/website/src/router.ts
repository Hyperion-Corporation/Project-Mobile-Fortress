import { createAppRouter } from "./libraries/router/createAppRouter";
import { searchIndex } from "./nav.generated";

const router = createAppRouter({
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("./views/HomeView.vue"),
    },
    {
      path: "/:pathMatch(.*)*",
      name: "doc",
      component: () => import("./views/DocPage.vue"),
    },
  ],
});

export function findPageBySource(source: string) {
  return searchIndex.find((p) => p.source === source);
}

export default router;
