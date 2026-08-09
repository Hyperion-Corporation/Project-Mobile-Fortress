import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useNavigate } from "react-router-dom";
import { searchIndex } from "../../../nav.generated";
import { useClickOutside } from "../../../hooks/useClickOutside";
import { useFocusWhen } from "../../../hooks/useFocusWhen";
import "./SearchBox.css";

export default function SearchBox() {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const modalRef = useRef<HTMLDivElement | null>(null);
  const navigate = useNavigate();

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return searchIndex.slice(0, 8);
    return searchIndex
      .filter((p) => p.title.toLowerCase().includes(q) || p.source.toLowerCase().includes(q))
      .slice(0, 20);
  }, [query]);

  useEffect(() => setActiveIndex(0), [results]);

  function openSearch() {
    setOpen(true);
    setQuery("");
  }
  function closeSearch() {
    setOpen(false);
  }
  function go(path: string) {
    navigate(path);
    closeSearch();
  }

  useClickOutside(modalRef, closeSearch);
  useFocusWhen(inputRef, open);

  useEffect(() => {
    function onKeydown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((wasOpen) => {
          if (wasOpen) return false;
          setQuery("");
          return true;
        });
        return;
      }
      if (!open) return;
      if (e.key === "Escape") closeSearch();
      if (e.key === "ArrowDown") {
        e.preventDefault();
        setActiveIndex((i) => Math.min(i + 1, results.length - 1));
      }
      if (e.key === "ArrowUp") {
        e.preventDefault();
        setActiveIndex((i) => Math.max(i - 1, 0));
      }
      if (e.key === "Enter") {
        const r = results[activeIndex];
        if (r) go(r.path);
      }
    }
    window.addEventListener("keydown", onKeydown);
    return () => window.removeEventListener("keydown", onKeydown);
    // Intentionally re-bound on every render so closures see latest open/results/activeIndex.
  });

  return (
    <>
      <button className="search-trigger" onClick={openSearch} aria-label="Search docs">
        <svg viewBox="0 0 20 20" width="15" height="15" fill="none">
          <circle cx="9" cy="9" r="6" stroke="currentColor" strokeWidth="1.8" />
          <path d="M17 17l-3.5-3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        </svg>
        <span className="search-trigger-text">Search docs…</span>
        <kbd>⌘K</kbd>
      </button>

      {open &&
        createPortal(
          <div className="search-overlay" onClick={(e) => e.target === e.currentTarget && closeSearch()}>
            <div className="search-modal" ref={modalRef}>
              <div className="search-input-row">
                <svg viewBox="0 0 20 20" width="16" height="16" fill="none">
                  <circle cx="9" cy="9" r="6" stroke="currentColor" strokeWidth="1.8" />
                  <path d="M17 17l-3.5-3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                </svg>
                <input
                  ref={inputRef}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  type="text"
                  placeholder="Search pages by title or path…"
                  autoComplete="off"
                />
                <kbd>Esc</kbd>
              </div>
              <div className="search-results">
                {results.map((r, i) => (
                  <button
                    key={r.path}
                    className={`search-result${i === activeIndex ? " active" : ""}`}
                    onMouseEnter={() => setActiveIndex(i)}
                    onClick={() => go(r.path)}
                  >
                    <span className="result-title">{r.title}</span>
                    <span className="result-path">{r.source}</span>
                  </button>
                ))}
                {results.length === 0 && <div className="search-empty">No pages found.</div>}
              </div>
            </div>
          </div>,
          document.body
        )}
    </>
  );
}
