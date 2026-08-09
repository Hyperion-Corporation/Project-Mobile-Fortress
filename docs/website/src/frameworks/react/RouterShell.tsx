import { RouterProvider } from "react-router-dom";
import router from "../../router";

/**
 * Wraps the shared react-router data router (src/router.tsx) for hosts that
 * can't statically import it — createBrowserRouter touches `window` at
 * module scope, so the stack/next/ surface loads this only client-side via
 * next/dynamic(..., { ssr: false }) rather than importing router.tsx directly.
 */
export default function RouterShell() {
  return <RouterProvider router={router} />;
}
