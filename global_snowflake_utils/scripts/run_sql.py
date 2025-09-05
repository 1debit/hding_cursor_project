import sys, pathlib
from typing import List
from src.sf_client import get_connection
from sqlalchemy import text

def split_sql(statements: str) -> List[str]:
    parts, current, in_str = [], [], False
    quote = None
    for ch in statements:
        if ch in ("'", '"'):
            if in_str and ch == quote:
                in_str = False
                quote = None
            elif not in_str:
                in_str = True
                quote = ch
        if ch == ";" and not in_str:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return [p for p in parts if p]

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/run_sql.py path/to/file.sql")
        sys.exit(1)
    sql_path = pathlib.Path(sys.argv[1])
    sql_text = sql_path.read_text(encoding="utf-8")
    stmts = split_sql(sql_text)
    print(f"Executing {len(stmts)} statements from {sql_path} ...")
    conn = get_connection()
    try:
        for i, stmt in enumerate(stmts, 1):
            preview = stmt[:120].replace('\n',' ')
            print(f"--- [{i}/{len(stmts)}] {preview}{'...' if len(stmt)>120 else ''}")
            result = conn.execute(text(stmt))
            try:
                rows = result.fetchmany(5)
                if rows:
                    print(f"  returned {len(rows)} rows (showing up to 5): {rows}")
            except Exception:
                pass
        print("Done ✅")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
