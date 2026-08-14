import { useEffect, useState } from "react";
import { Link, Outlet, ScrollRestoration, useLocation } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import SearchBox from "./components/SearchBox";
import ThemeToggle from "./components/ThemeToggle";
import "./App.css";

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  useEffect(() => setSidebarOpen(false), [location.pathname]);

  // The "/" route is the interactive design-hub landing page, not a doc — hide
  // the persistent docs sidebar there so the hero reads as a full-width page,
  // and show it (with a full nav grid) for every actual documentation route.
  const isHome = location.pathname === "/";

  return (
    <div className="layout">
      <header className="topbar">
        <div className="topbar-left">
          {!isHome && (
            <button
              className="menu-btn"
              onClick={() => setSidebarOpen((v) => !v)}
              aria-label="Toggle navigation"
            >
              <svg viewBox="0 0 20 20" width="18" height="18" fill="none">
                <path d="M3 5h14M3 10h14M3 15h14" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
              </svg>
            </button>
          )}
          <Link to="/" className="brand">
            <span className="brand-mark">🏯</span>
            <span className="brand-name">Mobile Fortress</span>
            <span className="brand-tag">嘉靖倭寇 1540s–1560s</span>
          </Link>
        </div>
        <div className="topbar-right">
          <Link to="/docs" className={`docs-link${!isHome ? " active" : ""}`}>
            Documentation
          </Link>
          <Link
            to="/dashboard"
            className={`docs-link${location.pathname.startsWith("/dashboard") ? " active" : ""}`}
          >
            Dashboard
          </Link>
          <SearchBox />
          <a
            className="icon-link"
            href="https://github.com/ACFHarbinger/Project-Mobile-Fortress"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="GitHub repository"
          >
            <svg viewBox="0 0 24 24" width="19" height="19" fill="currentColor">
              <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.833.092-.647.35-1.088.636-1.339-2.221-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.269 2.75 1.026A9.564 9.564 0 0 1 12 6.844c.85.004 1.705.115 2.504.337 1.909-1.295 2.747-1.026 2.747-1.026.546 1.378.203 2.397.1 2.65.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.744 0 .268.18.58.688.482A10.02 10.02 0 0 0 22 12.017C22 6.484 17.523 2 12 2Z" />
            </svg>
          </a>
          <ThemeToggle />
        </div>
      </header>

      <div className={`body${isHome ? " body-full" : ""}`}>
        {!isHome && <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />}
        <main className="content">
          <Outlet />
        </main>
      </div>
      <ScrollRestoration />
    </div>
  );
}
