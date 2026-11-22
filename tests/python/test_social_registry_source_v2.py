import json, unittest, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"tests/python"))
from validate_social_registry_source_v2 import validate
D=json.loads((ROOT/"data/social/social_registry_v0.2.json").read_text(encoding="utf-8"))
class TestSocialV2(unittest.TestCase):
 def test_180_people(self): self.assertEqual(len(D["people"]),180)
 def test_60_named_120_background(self):
  self.assertEqual(sum(p.get("population_layer")=="authored_named_cast" for p in D["people"]),60)
  self.assertEqual(sum(p.get("population_layer")=="background_seeded_population" for p in D["people"]),120)
 def test_40_households_three_each(self):
  self.assertEqual(len(D["households"]),40); self.assertTrue(all(len(h["member_person_ids"])==3 for h in D["households"]))
 def test_no_kinship_assumed(self): self.assertTrue(all(h["family_status"]=="kinship_unknown_not_inferred" for h in D["households"]))
 def test_no_residence_assignments(self): self.assertTrue(all(p["residence_facility_id"] is None for p in D["people"]))
 def test_relationship_edges(self): self.assertEqual(sum(r["relationship_type"]=="same_household_member" for r in D["relationships"]),240)
 def test_original_kall_inference_unconfirmed(self): self.assertEqual(next(r for r in D["relationships"] if r["relationship_id"]=="REL-KALL-001")["status"],"high_confidence_inference_pending_author_confirmation")
 def test_four_unresolved_claims(self): self.assertEqual(len(D["unresolved_social_claims"]),4)
 def test_all_references(self): self.assertEqual(validate(D),[])
if __name__=="__main__": unittest.main()
