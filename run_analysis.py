"""Loads the CSVs into SQLite and runs every query in queries.sql, printing the results."""
import csv, sqlite3, re

conn = sqlite3.connect("sales.db")
for table in ("products", "customers", "orders"):
    with open(f"{table}.csv") as f:
        r = csv.reader(f); cols = next(r)
        conn.execute(f"DROP TABLE IF EXISTS {table}")
        conn.execute(f"CREATE TABLE {table} ({', '.join(cols)})")
        conn.executemany(f"INSERT INTO {table} VALUES ({','.join('?' * len(cols))})",
                         [[float(v) if re.fullmatch(r'-?\d+(\.\d+)?', v) else v for v in row] for row in r])
conn.commit()

sql = open("queries.sql").read()
for block in re.split(r"\n(?=-- Q\d)", sql)[1:]:
    title = block.splitlines()[0]
    rows = conn.execute(block).fetchall()
    cols = [d[0] for d in conn.execute(block).description]
    print(f"\n{title}\n" + " | ".join(cols))
    for row in rows[:12]:
        print(" | ".join(str(int(v)) if isinstance(v, float) and v.is_integer() else str(v) for v in row))
    if len(rows) > 12: print(f"... ({len(rows)} rows)")
