// `import.meta.env.BASE_URL` is a Vite-ism (undefined under webpack, i.e. the
// stack/next/ surface — reading `.BASE_URL` off `undefined` throws
// "Cannot read properties of undefined"). Read it defensively and fall back
// to "/" (Next always serves this alt surface from the root, no subpath
// support needed there — see stack/next/README.md).
export function siteBaseUrl(): string {
  try {
    return import.meta.env?.BASE_URL ?? "/";
  } catch {
    return "/";
  }
}
