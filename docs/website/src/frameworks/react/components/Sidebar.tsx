import { navTree } from "../../../nav.generated";
import SidebarSection from "./SidebarSection";
import "./Sidebar.css";

export default function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <>
      {open && <div className="sidebar-scrim" onClick={onClose} />}
      <nav className={`sidebar${open ? " open" : ""}`}>
        {navTree.map((node, i) => (
          <SidebarSection key={i} node={node} depth={0} />
        ))}
      </nav>
    </>
  );
}
