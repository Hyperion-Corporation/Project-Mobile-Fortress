import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import type { NavNode } from "../../../nav.generated";
import "./SidebarSection.css";

function containsActive(node: NavNode, path: string): boolean {
  if (node.kind === "section") return node.children.some((child) => containsActive(child, path));
  if (node.kind === "external") return false;
  return node.path === path;
}

export default function SidebarSection({ node, depth }: { node: NavNode; depth: number }) {
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(
    node.kind === "section" ? containsActive(node, location.pathname) || depth === 0 : false
  );

  if (node.kind === "section") {
    return (
      <div className="nav-section" style={{ "--depth": depth } as React.CSSProperties}>
        <button
          className={`nav-section-toggle${isOpen ? " open" : ""}`}
          onClick={() => setIsOpen((v) => !v)}
        >
          <span className="chevron">▸</span>
          {node.title}
        </button>
        {isOpen && (
          <div className="nav-children">
            {node.children.map((child, i) => (
              <SidebarSection key={i} node={child} depth={depth + 1} />
            ))}
          </div>
        )}
      </div>
    );
  }

  if (node.kind === "external") {
    return (
      <a
        className="nav-leaf nav-external"
        href={node.href}
        target="_blank"
        rel="noopener noreferrer"
        style={{ "--depth": depth } as React.CSSProperties}
      >
        {node.title} <span className="ext-icon">↗</span>
      </a>
    );
  }

  const isActive = node.path === location.pathname;
  return (
    <Link
      className={`nav-leaf${isActive ? " active" : ""}`}
      to={node.path}
      style={{ "--depth": depth } as React.CSSProperties}
    >
      {node.title}
    </Link>
  );
}
