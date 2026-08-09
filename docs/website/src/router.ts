import { createRouter, createWebHistory } from "vue-router";
import { searchIndex } from "./nav.generated";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition;
    if (to.hash) return { el: to.hash, behavior: "smooth", top: 80 };
    return { top: 0 };
  },
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("./views/HomeView.vue"), // pages live under src/views
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
