#!/usr/bin/env python3
"""Rebuild Social Registry v0.2 from exact source JSON and v0.1 template."""
from __future__ import annotations
import argparse, json
from collections import defaultdict, Counter
from pathlib import Path

def read(path): return json.loads(Path(path).read_text(encoding="utf-8"))
def build(template, named, background, combined):
    assert len(template["people"]) == 60
    assert len(named) == 60 and len(background["npcs"]) == 120
    assert combined["total_count"] == 180 and len(combined["npcs"]) == 180
    people=[dict(p) for p in template["people"]]
    for p in people:
        p.setdefault("population_layer","authored_named_cast")
        p.setdefault("source_record","npc_named_cast.csv")
    ids={p["person_id"] for p in people}
    bg_ids={p["id"] for p in background["npcs"]}
    if ids & bg_ids: raise ValueError("ID collision between named and background population")
    for src in background["npcs"]:
        people.append({
          "person_id":src["id"], "display_name":src["name"],
          "population_layer":src.get("population_layer","background_seeded_population"),
          "name_status":src.get("name_status"), "source_role":src.get("role"),
          "source_role_key":src.get("role_key"), "source_work_area":src.get("district_or_work_area"),
          "motivation_summary":src.get("primary_motivation"), "personality_traits":src.get("personality_traits",[]),
          "routine_summary":src.get("routine_summary"), "knowledge_scope":src.get("knowledge_scope"),
          "aptitudes":src.get("aptitudes"), "aptitude_profile_key":src.get("aptitude_profile_key"),
          "declared_affiliation_ids":[], "family_group_ids":[], "household_id":src.get("household_id"),
          "residence_facility_id":None,
          "residence_status":"household_group_known_but_physical_residence_unassigned",
          "social_attributes":{"age":None,"species_or_people":src.get("species_id"),"culture":None,"languages":None,"legal_status":None,
            "notes":"No se deducen edad, cultura, idioma ni estado jurídico; especie/plantilla de especie conservada como ID fuente."},
          "relationship_views":src.get("relationships",[]), "source_record":"npc_background_population.json",
          "source_identity":{"entity_id":src.get("entity_id"),"universal_identity_id":src.get("universal_identity_id"),
            "life_episode_id":src.get("life_episode_id"),"body_id":src.get("body_id"),"cognitive_profile_id":src.get("cognitive_profile_id"),"social_identity_id":src.get("social_identity_id")},
          "life_status_source":src.get("life_status"), "simulation_tier":src.get("simulation_tier"),
          "identity_persistence":src.get("identity_persistence")
        })
    household_members=defaultdict(list)
    for src in background["npcs"]:
        if not src.get("household_id"): raise ValueError("missing household_id: "+src["id"])
        household_members[src["household_id"]].append(src["id"])
    households=[]
    for hid,members in sorted(household_members.items()):
        households.append({"household_id":hid,"member_person_ids":sorted(members),
          "household_type":"seeded_shared_household_group_type_unclassified","membership_status":"source_declared_seed_group",
          "source_world_seed":background["world_seed"],"source_generator_version":background["generator_version"],
          "residence_facility_id":None,"physical_address":None,
          "physical_residence_status":"not_assigned_no_validated_spatial_address",
          "family_status":"kinship_unknown_not_inferred","shared_assets_or_accounts":None,"capacity":None,
          "notes":"The NPC source explicitly gives the same household_id and same_household_member links. This confirms a generated household grouping only; it does not infer family, legal status, affection, ownership, exact building or address."})
    relationships=[dict(r) for r in template["relationships"]]
    for src in background["npcs"]:
        for rel in src.get("relationships",[]):
            target=rel.get("target_id")
            if target not in bg_ids: raise ValueError(f"invalid household target {target}")
            relationships.append({"relationship_id":f"REL-HH-{src['id']}-{target}",
              "source_person_id":src["id"],"target_person_id":target,
              "relationship_type":"same_household_member","reciprocal_type":"same_household_member",
              "status":"source_declared_household_membership_not_kinship",
              "evidence":[f"NPC source relationship: {rel.get('type')}"],
              "evidence_source":"npc_background_population.json; exact source record preserved",
              "confidence":"explicit_source_group_membership_only","household_id":src.get("household_id"),
              "source_basis":rel.get("basis"),"social_affinity_dimensions":None,
              "notes":"This is a household co-membership edge, not proof of kinship, friendship, trust, romance, debt or family."})
    out=dict(template); out["metadata"]=dict(template["metadata"]); out["metadata"]["scope"]=dict(template["metadata"]["scope"])
    out["metadata"].update({"version":"0.2.0","source_npc_catalogue":"NPC Poblacion Inicial v0.1; exact combined set of 60 named + 120 background NPC",
      "population_source_world_seed":background["world_seed"],"population_source_generator_version":background["generator_version"]})
    out["metadata"]["scope"].update({"named_people_included":60,"background_population_imported":120,"total_people_included":180,
      "background_household_groups_imported":len(households),"background_household_membership_links_imported":sum(len(x.get("relationships",[])) for x in background["npcs"]),
      "background_population_status":"imported_from_exact_user_supplied_source_zip; IDs preserved; no regeneration"})
    out["people"]=people; out["households"]=households; out["relationships"]=relationships
    out["background_population_import_contract"]={"status":"imported_and_validated_v0.2.0","source_file":"npc_background_population.json",
      "source_archive":"World_Laboratory_NPC_Poblacion_Inicial_v0.1.zip","source_world_seed":background["world_seed"],
      "source_generator_version":background["generator_version"],"imported_person_count":120,"imported_household_count":len(households),
      "imported_household_membership_link_count":sum(len(x.get("relationships",[])) for x in background["npcs"]),
      "identity_rule":"All source person/entity/universal identity/life episode/body/cognitive/social IDs are preserved as imported; do not regenerate or normalize them.",
      "relationship_rule":"Only source-declared same_household_member links are imported. No kinship or affinity is inferred.",
      "residence_rule":"Household IDs are imported, but no building, address, coordinates, ownership or capacity is assigned.",
      "demographic_rule":"Missing age, culture, language, legal status and relationship details remain unknown.",
      "rebuild_rule":"Rebuild only from exact source archive and same version/seed; never silently regenerate a live saved world."}
    out["population_import_audit"]={"named_count":60,"background_count":120,"total_count":180,"combined_source_reported_count":combined["total_count"],
      "all_ids_unique":len({x["id"] for x in combined["npcs"]})==180,"named_ids_preserved":True,"background_ids_preserved":True,
      "household_groups":len(households),"all_household_sizes":dict(Counter(len(h["member_person_ids"]) for h in households)),
      "kinship_inferred_from_household":False,"physical_residences_assigned":0}
    return out
if __name__ == "__main__":
    ap=argparse.ArgumentParser(); ap.add_argument("--template",default="data/social/source/social_registry_v0.1_template.json"); ap.add_argument("--named",default="data/social/source/npc_named_cast.json"); ap.add_argument("--background",default="data/social/source/npc_background_population.json"); ap.add_argument("--combined",default="data/social/source/npc_initial_population.json"); ap.add_argument("--output",default="data/social/social_registry_v0.2.json"); a=ap.parse_args()
    obj=build(read(a.template),read(a.named),read(a.background),read(a.combined)); Path(a.output).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n",encoding="utf-8"); print(f"Built {len(obj['people'])} people, {len(obj['households'])} households, {len(obj['relationships'])} relationships")
