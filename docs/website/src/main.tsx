import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { RouterProvider } from "react-router-dom";
import router from "./router";
import ReduxProvider from "./libraries/redux/store/ReduxProvider";
import "./styles/tailwind.css";
import "./styles/theme.css";
import "./styles/markdown.css";
import "./styles/hub.css";
import "highlight.js/styles/github-dark.css";
import "katex/dist/katex.min.css";

createRoot(document.getElementById("app")!).render(
  <StrictMode>
    <ReduxProvider>
      <RouterProvider router={router} />
    </ReduxProvider>
  </StrictMode>
);
