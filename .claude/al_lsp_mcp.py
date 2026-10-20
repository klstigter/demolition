"""Minimal MCP (stdio) bridge to `al launchlspserver`.
Tools: al_lsp_definition, al_lsp_references, al_lsp_rename (preview only, never writes files).
Positions are 1-based line/column; `file` is relative to the project root.
"""
import json, pathlib, subprocess, sys, time

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
lsp = None
next_id = 0
opened = {}


def lsp_send(m):
    b = json.dumps(m).encode()
    lsp.stdin.write(b"Content-Length: %d\r\n\r\n" % len(b) + b)
    lsp.stdin.flush()


def lsp_read():
    h = b""
    while not h.endswith(b"\r\n\r\n"):
        c = lsp.stdout.read(1)
        if not c:
            return None
        h += c
    n = int([x for x in h.decode().split("\r\n") if x.lower().startswith("content-length")][0].split(":")[1])
    return json.loads(lsp.stdout.read(n))


def lsp_req(method, params):
    global next_id
    next_id += 1
    rid = next_id
    lsp_send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params})
    while True:
        m = lsp_read()
        if m is None:
            raise RuntimeError("LSP server exited")
        if "method" in m and "id" in m:
            lsp_send({"jsonrpc": "2.0", "id": m["id"], "result": None})
        elif m.get("id") == rid:
            if "error" in m:
                raise RuntimeError(json.dumps(m["error"]))
            return m.get("result")


def ensure_lsp():
    global lsp
    if lsp:
        return
    lsp = subprocess.Popen(
        ["al", "launchlspserver", str(ROOT), "--packagecachepath", str(ROOT / ".alpackages"), "--disableTelemetry"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    lsp_req("initialize", {"processId": None, "rootUri": ROOT.as_uri(), "capabilities": {},
                           "workspaceFolders": [{"uri": ROOT.as_uri(), "name": ROOT.name}]})
    lsp_send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
    time.sleep(20)  # project load


def open_doc(rel):
    path = ROOT / rel
    uri = path.as_uri()
    if uri in opened:
        lsp_send({"jsonrpc": "2.0", "method": "textDocument/didClose", "params": {"textDocument": {"uri": uri}}})
    opened[uri] = opened.get(uri, 0) + 1
    lsp_send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {
        "uri": uri, "languageId": "al", "version": opened[uri], "text": path.read_text(encoding="utf-8-sig")}}})
    return uri


def rel_uri(u):
    return u.replace(ROOT.as_uri() + "/", "")


def fmt_locs(res):
    if not res:
        return "no results"
    if isinstance(res, dict):
        res = [res]
    return "\n".join(f"{rel_uri(x.get('uri') or x.get('targetUri'))}:{(x.get('range') or x['targetSelectionRange'])['start']['line'] + 1}"
                     for x in res)


def call(name, a):
    ensure_lsp()
    uri = open_doc(a["file"])
    td = {"textDocument": {"uri": uri}, "position": {"line": a["line"] - 1, "character": a["column"] - 1}}
    if name == "al_lsp_definition":
        return fmt_locs(lsp_req("textDocument/definition", td))
    if name == "al_lsp_references":
        return fmt_locs(lsp_req("textDocument/references", {**td, "context": {"includeDeclaration": True}}))
    if name == "al_lsp_rename":
        r = lsp_req("textDocument/rename", {**td, "newName": a["new_name"]}) or {}
        ch = r.get("changes") or {}
        for dc in r.get("documentChanges") or []:
            ch.setdefault(dc["textDocument"]["uri"], []).extend(dc["edits"])
        return "PREVIEW (nothing written):\n" + "\n".join(
            f"{rel_uri(u)}:{e['range']['start']['line'] + 1} -> {e['newText']}" for u, es in ch.items() for e in es) or "no edits"
    raise ValueError(name)


POS = {"file": {"type": "string", "description": "path relative to project root"},
       "line": {"type": "integer", "description": "1-based"}, "column": {"type": "integer", "description": "1-based"}}
TOOLS = [
    {"name": "al_lsp_definition", "description": "AL LSP: go to definition of the symbol at a position.",
     "inputSchema": {"type": "object", "properties": POS, "required": ["file", "line", "column"]}},
    {"name": "al_lsp_references", "description": "AL LSP: semantic find-all-references (incl. declaration) across the project and its dependencies.",
     "inputSchema": {"type": "object", "properties": POS, "required": ["file", "line", "column"]}},
    {"name": "al_lsp_rename", "description": "AL LSP: preview a rename (returns edits, does not modify files).",
     "inputSchema": {"type": "object", "properties": {**POS, "new_name": {"type": "string"}},
                     "required": ["file", "line", "column", "new_name"]}},
]

for raw in sys.stdin:
    if not raw.strip():
        continue
    m = json.loads(raw)
    mid, meth = m.get("id"), m.get("method")
    if mid is None:
        continue
    try:
        if meth == "initialize":
            res = {"protocolVersion": m["params"].get("protocolVersion", "2024-11-05"),
                   "capabilities": {"tools": {}}, "serverInfo": {"name": "al-lsp", "version": "1.0"}}
        elif meth == "tools/list":
            res = {"tools": TOOLS}
        elif meth == "tools/call":
            try:
                res = {"content": [{"type": "text", "text": call(m["params"]["name"], m["params"]["arguments"])}]}
            except Exception as e:
                res = {"isError": True, "content": [{"type": "text", "text": str(e)}]}
        else:
            res = {}
        out = {"jsonrpc": "2.0", "id": mid, "result": res}
    except Exception as e:
        out = {"jsonrpc": "2.0", "id": mid, "error": {"code": -32603, "message": str(e)}}
    sys.stdout.write(json.dumps(out) + "\n")
    sys.stdout.flush()
