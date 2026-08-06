import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import "./styles/theme.css";
import "./styles/markdown.css";
import "./styles/hub.css";
import "highlight.js/styles/github-dark.css";
import "katex/dist/katex.min.css";

createApp(App).use(router).mount("#app");
