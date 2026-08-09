import type { Metadata } from "next";
import type { ReactNode } from "react";
import ReduxProvider from "../src/libraries/redux/store/ReduxProvider";
import "../src/styles/tailwind.css";
import "../src/styles/theme.css";
import "../src/styles/markdown.css";
import "../src/styles/hub.css";
import "highlight.js/styles/github-dark.css";
import "katex/dist/katex.min.css";

export const metadata: Metadata = {
  title: "Mobile Fortress Docs",
  description: "Documentation portal and design hub for Mobile Fortress.",
};

/**
 * Root layout for the stack/next/ surface — same providers and global CSS as
 * the Vite entry (src/main.tsx), since this mounts the identical
 * src/frameworks/react/ shell under Next's App Router instead of Vite.
 */
export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ReduxProvider>{children}</ReduxProvider>
      </body>
    </html>
  );
}
