import { createApp } from "vue";
import App from "./frameworks/vue/App.vue";
import router from "./router";
import { installVuex } from "./libraries/vuex/store/VuexProvider";
import { directivesPlugin } from "./frameworks/vue/directives";
import "./styles/tailwind.css";
import "./styles/theme.css";
import "./styles/markdown.css";
import "./styles/hub.css";
import "highlight.js/styles/github-dark.css";
import "katex/dist/katex.min.css";

const app = createApp(App);
installVuex(app);
app.use(directivesPlugin);
app.use(router).mount("#app");
