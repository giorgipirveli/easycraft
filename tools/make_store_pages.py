#!/usr/bin/env python3
"""The game's public web pages (Google Play links to them; owner feedback #46): the privacy policy and how to
delete an online account, made from docs/store/*.md into server/deploy/site/<name>/index.html, which the
server's Caddy serves at https://<domain>/privacy and /delete-account (server/deploy/caddy/Caddyfile).
Run from the project root after changing the Markdown:  python3 tools/make_store_pages.py
(needs Python's `markdown` package). The note block at the top of a source (lines starting with ">") is left out."""
import pathlib, re, markdown

PAGES = {"privacy": "docs/store/privacy-policy.md", "delete-account": "docs/store/delete-account.md"}
OUT = pathlib.Path("server/deploy/site")
STYLE = """body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:760px;margin:0 auto;
padding:24px 16px 64px;line-height:1.55;color:#1d2330;background:#fdfbf6}h1{font-size:1.8em;color:#2f6f3e}
h2{margin-top:1.6em;color:#2f6f3e}table{border-collapse:collapse;width:100%;font-size:.95em;display:block;
overflow-x:auto}th,td{border:1px solid #d9d4c7;padding:6px 8px;text-align:left;vertical-align:top}
th{background:#efe9da}a{color:#1f5fa8}@media(prefers-color-scheme:dark){body{background:#15181f;color:#e6e6e6}
th{background:#262b36}th,td{border-color:#3a404d}h1,h2{color:#7fd08f}a{color:#8ab8ff}}"""


def page(name: str, source: str) -> str:
    text = pathlib.Path(source).read_text(encoding="utf-8")
    lines = [l for l in text.split("\n") if not l.startswith(">")]   # the repo's own notes
    body = markdown.markdown("\n".join(lines), extensions=["tables"])
    title = re.search(r"<h1>(.*?)</h1>", body)
    return ("<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
            f"<title>{title.group(1) if title else 'EasyCraft'}</title><style>{STYLE}</style></head>"
            f"<body>\n{body}\n</body></html>\n")


if __name__ == "__main__":
    for name, source in PAGES.items():
        out = OUT / name / "index.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page(name, source), encoding="utf-8")
        print("STORE_PAGE", out)
