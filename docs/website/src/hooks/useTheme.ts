import { useCallback, useEffect } from "react";
import { useAppDispatch, useAppSelector } from "../libraries/redux/store/hooks";
import { setTheme } from "../libraries/redux/actions/appActions";

/**
 * Theme is Redux-owned (src/libraries/redux) rather than component-local
 * state, so the topbar toggle, the doc renderer's Mermaid theme, and any
 * future consumer stay in sync from a single source of truth.
 */
export function useTheme() {
  const theme = useAppSelector((state) => state.app.theme);
  const dispatch = useAppDispatch();

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  const toggle = useCallback(() => {
    dispatch(setTheme(theme === "light" ? "dark" : "light"));
  }, [dispatch, theme]);

  return { theme, toggle };
}
