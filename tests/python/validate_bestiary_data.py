#!/usr/bin/env python3
"""Cross-check the floor-one JSON subset against the supplied authoritative CSV."""
import csv, json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
json_path = ROOT / "data/bestiary/floor01_species.json"
csv_path = ROOT / "data/bestiary/estadisticas_especies_fuente.csv"
profiles = json.loads(json_path.read_text(encoding="utf-8"))["species"]
with csv_path.open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter=";"))
source = {row["id"]: row for row in rows}
errors=[]
expected = [f"MON-F1-{n:03d}" for n in range(1,6)]
if [x.get("id") for x in profiles] != expected:
    errors.append("The five first-floor bestiary entries are missing or out of order.")
for item in profiles:
    row = source.get(item["id"])
    if row is None:
        errors.append(f"{item['id']}: missing source CSV row")
        continue
    for json_key,csv_key in [("fuerza","fuerza"),("potencia","potencia"),("agilidad","agilidad"),("coordinacion","coordinacion"),("resistencia_fisica","resistencia_fisica"),("percepcion","percepcion")]:
        if int(item["stats"].get(json_key,-1)) != int(row[csv_key]):
            errors.append(f"{item['id']}: {json_key} disagrees with source CSV")
    if int(item.get("danger",-1)) != int(row["peligro"]):
        errors.append(f"{item['id']}: danger disagrees with source CSV")
if errors:
    print("BESTIARY VALIDATION FAILED")
    print("\n".join("- "+x for x in errors))
    sys.exit(1)
print(f"BESTIARY VALIDATION PASSED: {len(profiles)} floor-one profiles cross-checked against source CSV.")
