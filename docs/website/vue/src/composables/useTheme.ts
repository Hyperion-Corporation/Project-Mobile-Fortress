import { ref, watchEffect } from "vue";

const STORAGE_KEY = "mobile-fortress-docs-theme";

function initial(): "light" | "dark" {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored === "light" || stored === "dark") return stored;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

const theme = ref<"light" | "dark">(initial());

watchEffect(() => {
  document.documentElement.setAttribute("data-theme", theme.value);
  localStorage.setItem(STORAGE_KEY, theme.value);
});

export function useTheme() {
  function toggle() {
    theme.value = theme.value === "light" ? "dark" : "light";
  }
  return { theme, toggle };
}
