import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useParams } from "react-router-dom";
import { searchIndex } from "../../../nav.generated";
import { loadDoc } from "../../../hooks/useDocs";
import { renderMarkdown, extractTitle, extractToc, type TocEntry } from "../../../hooks/useMarkdown";
import "./DocPage.css";

const REPO_EDIT_BASE = "https://github.com/ACFHarbinger/Project-Mobile-Fortress/edit/main/";

async function renderMermaid(contentEl: HTMLElement | null) {
  const nodes = contentEl?.querySelectorAll<HTMLElement>(".mermaid");
  if (!nodes || !nodes.length) return;
  const mermaid = (await import("mermaid")).default;
  mermaid.initialize({
    startOnLoad: false,
    theme: document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "default",
    securityLevel: "loose",
  });
  try {
    await mermaid.run({ nodes: Array.from(nodes) });
  } catch (e) {
    console.warn("mermaid render failed", e);
  }
}

function addCopyButtons(contentEl: HTMLElement | null) {
  const blocks = contentEl?.querySelectorAll<HTMLElement>("pre.hljs");
  blocks?.forEach((pre) => {
    if (pre.querySelector(".copy-btn")) return;
    const code = pre.querySelector("code");
    if (!code) return;
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "copy-btn";
    btn.textContent = "Copy";
    btn.addEventListener("click", () => {
      navigator.clipboard.writeText(code.textContent || "").then(() => {
        btn.textContent = "Copied!";
        setTimeout(() => (btn.textContent = "Copy"), 1500);
      });
    });
    pre.appendChild(btn);
  });
}

export default function DocPage() {
  const location = useLocation();
  const params = useParams();

  const [state, setState] = useState<"loading" | "ok" | "notfound">("loading");
  const [html, setHtml] = useState("");
  const [title, setTitle] = useState("");
  const [toc, setToc] = useState<TocEntry[]>([]);
  const [editSource, setEditSource] = useState("");
  const contentRef = useRef<HTMLDivElement | null>(null);

  const currentPath = (() => {
    const wildcard = params["*"] ?? "";
    const p = "/" + wildcard;
    return p.replace(/\/$/, "") || "/";
  })();

  const currentIndex = searchIndex.findIndex((p) => p.path === currentPath);
  const prevDoc = currentIndex > 0 ? searchIndex[currentIndex - 1] : null;
  const nextDoc = currentIndex >= 0 && currentIndex < searchIndex.length - 1 ? searchIndex[currentIndex + 1] : null;

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setState("loading");
      const entry = searchIndex.find((p) => p.path === currentPath);
      if (!entry) {
        if (!cancelled) setState("notfound");
        return;
      }
      setEditSource(entry.source);

      const raw = await loadDoc(entry.source);
      if (cancelled) return;
      if (raw === null) {
        setState("notfound");
        return;
      }
      const nextTitle = extractTitle(raw) || entry.title;
      setTitle(nextTitle);
      setToc(extractToc(raw));
      setHtml(renderMarkdown(raw));
      setState("ok");
      document.title = `${nextTitle} — Mobile Fortress Docs`;
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [location.pathname]);

  useEffect(() => {
    if (state !== "ok") return;
    renderMermaid(contentRef.current);
    addCopyButtons(contentRef.current);
  }, [state, html]);

  if (state === "loading") {
    return (
      <div className="doc-page">
        <div className="doc-loading">Loading…</div>
      </div>
    );
  }

  if (state === "notfound") {
    return (
      <div className="doc-page">
        <div className="doc-notfound">
          <h1>404</h1>
          <p>
            No page found for <code>{currentPath}</code>.
          </p>
          <Link to="/docs">← Back to documentation</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="doc-page">
      <article className="doc-content">
        <div ref={contentRef} className="markdown-body" dangerouslySetInnerHTML={{ __html: html }} />
        <a className="edit-link" href={REPO_EDIT_BASE + editSource} target="_blank" rel="noopener noreferrer">
          Edit this page on GitHub ↗
        </a>

        <nav className="prev-next">
          {prevDoc ? (
            <Link to={prevDoc.path} className="prev-next-link prev">
              <span>← Previous</span>
              {prevDoc.title}
            </Link>
          ) : (
            <span />
          )}
          {nextDoc ? (
            <Link to={nextDoc.path} className="prev-next-link next">
              <span>Next →</span>
              {nextDoc.title}
            </Link>
          ) : (
            <span />
          )}
        </nav>
      </article>

      {toc.length > 0 && (
        <aside className="doc-toc">
          <div className="doc-toc-title">On this page</div>
          <nav>
            {toc.map((entry) => (
              <a key={entry.id} href={"#" + entry.id} className={`toc-link toc-level-${entry.level}`}>
                {entry.text}
              </a>
            ))}
          </nav>
        </aside>
      )}
    </div>
  );
}
