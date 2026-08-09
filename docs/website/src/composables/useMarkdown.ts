import MarkdownIt from "markdown-it";
import anchor from "markdown-it-anchor";
import texmath from "markdown-it-texmath";
import katex from "katex";
import hljs from "highlight.js/lib/core";
import kotlin from "highlight.js/lib/languages/kotlin";
import swift from "highlight.js/lib/languages/swift";
import cpp from "highlight.js/lib/languages/cpp";
import cmake from "highlight.js/lib/languages/cmake";
import bash from "highlight.js/lib/languages/bash";
import yamlLang from "highlight.js/lib/languages/yaml";
import json from "highlight.js/lib/languages/json";
import xml from "highlight.js/lib/languages/xml";
import ini from "highlight.js/lib/languages/ini";
import typescript from "highlight.js/lib/languages/typescript";
import javascript from "highlight.js/lib/languages/javascript";

hljs.registerLanguage("kotlin", kotlin);
hljs.registerLanguage("swift", swift);
hljs.registerLanguage("cpp", cpp);
hljs.registerLanguage("c++", cpp);
hljs.registerLanguage("cmake", cmake);
hljs.registerLanguage("bash", bash);
hljs.registerLanguage("sh", bash);
hljs.registerLanguage("yaml", yamlLang);
hljs.registerLanguage("yml", yamlLang);
hljs.registerLanguage("json", json);
hljs.registerLanguage("xml", xml);
hljs.registerLanguage("html", xml);
hljs.registerLanguage("ini", ini);
hljs.registerLanguage("toml", ini);
hljs.registerLanguage("properties", ini);
hljs.registerLanguage("typescript", typescript);
hljs.registerLanguage("ts", typescript);
hljs.registerLanguage("javascript", javascript);
hljs.registerLanguage("js", javascript);

const md = new MarkdownIt({
  html: true,
  linkify: true,
  typographer: true,
  highlight(str, lang) {
    if (lang === "mermaid") {
      return `<div class="mermaid">${md.utils.escapeHtml(str)}</div>`;
    }
    if (lang && hljs.getLanguage(lang)) {
      try {
        return `<pre class="hljs"><code>${hljs.highlight(str, { language: lang }).value}</code></pre>`;
      } catch {
        /* fall through */
      }
    }
    return `<pre class="hljs"><code>${md.utils.escapeHtml(str)}</code></pre>`;
  },
})
  .use(anchor, {
    permalink: anchor.permalink.linkInsideHeader({ symbol: "#", placement: "before" }),
  })
  .use(texmath, { engine: katex, delimiters: "dollars", katexOptions: { throwOnError: false } });

// Open external links in a new tab.
const defaultLinkRender =
  md.renderer.rules.link_open || ((tokens, idx, options, _env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  const href = token.attrGet("href") || "";
  if (/^https?:\/\//.test(href)) {
    token.attrSet("target", "_blank");
    token.attrSet("rel", "noopener noreferrer");
  }
  return defaultLinkRender(tokens, idx, options, env, self);
};

/** Strip mkdocs-only `{: #anchor }` attr_list suffixes markdown-it doesn't understand. */
function stripAttrList(src: string): string {
  return src.replace(/\{:\s*#[\w-]+\s*\}/g, "");
}

export function renderMarkdown(src: string): string {
  return md.render(stripAttrList(src));
}

export function extractTitle(src: string): string | null {
  const match = src.match(/^#\s+(.+)$/m);
  return match ? match[1].replace(/[*`]/g, "").trim() : null;
}

export interface TocEntry {
  level: number;
  text: string;
  id: string;
}

export function extractToc(src: string): TocEntry[] {
  const toc: TocEntry[] = [];
  const lines = stripAttrList(src).split("\n");
  let inFence = false;
  for (const line of lines) {
    if (/^```/.test(line)) inFence = !inFence;
    if (inFence) continue;
    const match = line.match(/^(#{2,3})\s+(.+)$/);
    if (match) {
      const text = match[2].replace(/[*`_]/g, "").trim();
      const id = text
        .toLowerCase()
        .replace(/[^\w\s-]/g, "")
        .trim()
        .replace(/\s+/g, "-");
      toc.push({ level: match[1].length, text, id });
    }
  }
  return toc;
}
