#!/usr/bin/env python3
import argparse, json, sys
from pathlib import Path

def validate(d):
    e=[]; people=d.get("people",[]); ids=[p.get("person_id") for p in people]; idset=set(ids)
    if len(people)!=180: e.append(f"expected 180 people, got {len(people)}")
    if len(idset)!=len(ids): e.append("duplicate person IDs")
    if sum(p.get("population_layer")=="background_seeded_population" for p in people)!=120: e.append("background population count mismatch")
    if sum(p.get("population_layer")=="authored_named_cast" for p in people)!=60: e.append("named cast count mismatch")
    household_ids={h.get("household_id") for h in d.get("households",[])}
    if len(household_ids)!=40: e.append(f"expected 40 imported households, got {len(household_ids)}")
    for p in people:
        if not p.get("person_id") or not p.get("display_name"): e.append("person missing id/name")
        if p.get("household_id") and p["household_id"] not in household_ids: e.append(f"missing household for {p['person_id']}")
        if p.get("residence_facility_id") is not None: e.append(f"unexpected physical residence assignment: {p['person_id']}")
        for fid in p.get("family_group_ids",[]):
            if fid not in {f.get("family_group_id") for f in d.get("families",[])}: e.append(f"missing family {fid}")
    for h in d.get("households",[]):
        members=h.get("member_person_ids",[])
        if len(members)!=3: e.append(f"household {h.get('household_id')} must have 3 source members")
        if any(x not in idset for x in members): e.append(f"household {h.get('household_id')} references missing person")
        if h.get("residence_facility_id") is not None: e.append(f"unapproved residence assigned to {h.get('household_id')}")
        if h.get("family_status")!="kinship_unknown_not_inferred": e.append(f"family inferred in {h.get('household_id')}")
    rels=d.get("relationships",[]); rids=[r.get("relationship_id") for r in rels]
    if len(rids)!=len(set(rids)): e.append("duplicate relationship IDs")
    for r in rels:
        if r.get("source_person_id") not in idset or r.get("target_person_id") not in idset: e.append(f"relationship endpoint missing: {r.get('relationship_id')}")
        if r.get("source_person_id")==r.get("target_person_id"): e.append(f"self relation: {r.get('relationship_id')}")
        if r.get("relationship_type")=="same_household_member" and r.get("confidence")!="explicit_source_group_membership_only": e.append("household edge without exact-source basis")
    if len([r for r in rels if r.get("relationship_type")=="same_household_member"])!=240: e.append("expected 240 same_household_member directed edges")
    if len(d.get("unresolved_social_claims",[]))!=4: e.append("unresolved social claims count changed")
    if len(d.get("families",[]))!=1: e.append("existing provisional Kall family record changed")
    if len(d.get("work_appointments_crosswalk",[]))!=5: e.append("expected 5 employment crosswalks")
    if any(x.get("employment_contract_status")!="not_established" for x in d.get("work_appointments_crosswalk",[])): e.append("employment contract falsely established")
    kall=[r for r in rels if r.get("relationship_id")=="REL-KALL-001"]
    if len(kall)!=1 or kall[0].get("status")=="confirmed": e.append("Kall inference improperly promoted")
    return e

if __name__=="__main__":
    ap=argparse.ArgumentParser(); ap.add_argument("json_path"); args=ap.parse_args(); d=json.loads(Path(args.json_path).read_text(encoding="utf-8")); errors=validate(d)
    if errors: print("FAIL\n"+"\n".join("- "+x for x in errors)); sys.exit(1)
    print(f"PASS: {len(d['people'])} persons; {len(d['households'])} source household groups; 240 household edges; {len(d['relationships'])} total relationships; 5 work crosswalks; 4 unresolved claims; no physical residences fabricated.")
