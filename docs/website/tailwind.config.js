/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx,astro}',
  ],
  // Align with theme toggle: `document.documentElement.dataset.theme`
  darkMode: ['selector', '[data-theme="dark"]'],
  theme: {
    screens: {
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
    },
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Cinzel', 'Georgia', 'serif'],
        mono: ['SFMono-Regular', 'Consolas', 'Menlo', 'monospace'],
      },
      colors: {
        // Map to design tokens in src/styles/theme.css
        accent: {
          DEFAULT: '#d90429',
          soft: '#fdecef',
          gold: '#f4d35e',
          rose: '#ff758f',
        },
        surface: {
          DEFAULT: 'var(--surface)',
          hover: 'var(--surface-hover)',
        },
        ink: {
          DEFAULT: 'var(--text)',
          muted: 'var(--text-muted)',
        },
      },
      borderRadius: {
        hub: 'var(--radius, 10px)',
      },
    },
  },
  plugins: [],
};
