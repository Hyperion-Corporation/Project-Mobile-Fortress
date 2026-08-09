import { createApp } from "vue";
import App from "./frameworks/vue/App.vue";
import router from "./frameworks/vue/router";
import "./frameworks/vue/styles/theme.css";
import "./frameworks/vue/styles/markdown.css";
import "./frameworks/vue/styles/hub.css";
import "highlight.js/styles/github-dark.css";
import "katex/dist/katex.min.css";

createApp(App).use(router).mount("#app");
