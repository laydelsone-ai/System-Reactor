extends RefCounted

const MAX_GAP_WARNING_SECONDS: int = 31536000 # 365 días; aviso, no recorte.

var world_tick: int = 0
var last_wall_epoch: int = 0

func calculate_offline_gap(previous_epoch: int, current_epoch: int) -> Dictionary:
	if previous_epoch <= 0:
		return {"elapsed_seconds": 0, "anomaly": "missing_previous_checkpoint"}
	if current_epoch < previous_epoch:
		return {"elapsed_seconds": 0, "anomaly": "system_clock_moved_backwards"}
	var elapsed: int = current_epoch - previous_epoch
	var anomaly: String = ""
	if elapsed > MAX_GAP_WARNING_SECONDS:
		anomaly = "gap_over_one_year_review"
	return {"elapsed_seconds": elapsed, "anomaly": anomaly}

func commit_wall_checkpoint(epoch: int) -> void:
	last_wall_epoch = maxi(epoch, 0)

func advance_world(seconds: int) -> void:
	world_tick += maxi(seconds, 0)
