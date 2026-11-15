class_name MissionProgress
extends RefCounted

## MissionProgress.gd - Manages campaign state, unlocks, and task completion verification.

var levels_data: Array = []
var completed_task_ids: Dictionary = {} # task_id -> { "player_value": Variant, "completed_at": int }
var unlocked_level_ids: Array[String] = ["LVL_01"]

func initialize_from_data(campaign_levels: Array) -> void:
	levels_data = campaign_levels.duplicate(true)
	# Level 1 is always unlocked by default
	if not unlocked_level_ids.has("LVL_01"):
		unlocked_level_ids.append("LVL_01")
	update_unlock_states()

func is_level_unlocked(level_id: String) -> bool:
	return unlocked_level_ids.has(level_id)

func is_task_completed(task_id: String) -> bool:
	return completed_task_ids.has(task_id)

func get_task(task_id: String) -> Dictionary:
	for lvl in levels_data:
		var tasks: Array = lvl.get("tasks", [])
		for t in tasks:
			if t.get("id", "") == task_id:
				return t
	return {}

func get_level(level_id: String) -> Dictionary:
	for lvl in levels_data:
		if lvl.get("id", "") == level_id:
			return lvl
	return {}

func get_tasks_for_level(level_id: String) -> Array:
	var lvl: Dictionary = get_level(level_id)
	return lvl.get("tasks", [])

func complete_task(level_id: String, task_id: String, player_val: Variant) -> bool:
	var lvl: Dictionary = get_level(level_id)
	if lvl.is_empty():
		return false
		
	var task: Dictionary = get_task(task_id)
	if task.is_empty():
		return false
		
	completed_task_ids[task_id] = {
		"player_value": player_val,
		"completed_at": Time.get_unix_time_from_system()
	}
	task["completed"] = true
	task["player_submitted_value"] = player_val
	
	check_and_update_level_completion(level_id)
	update_unlock_states()
	return true

func certify_level(level_id: String) -> void:
	var lvl: Dictionary = get_level(level_id)
	if lvl.is_empty():
		return
	var tasks: Array = lvl.get("tasks", [])
	for t in tasks:
		var tid: String = t.get("id", "")
		var target_val = t.get("target_value", 1.0)
		if not completed_task_ids.has(tid):
			completed_task_ids[tid] = {
				"player_value": target_val,
				"completed_at": Time.get_unix_time_from_system()
			}
			t["completed"] = true
			t["player_submitted_value"] = target_val
	check_and_update_level_completion(level_id)
	update_unlock_states()

func are_all_level_tasks_completed(level_id: String) -> bool:
	var lvl: Dictionary = get_level(level_id)
	if lvl.is_empty():
		return false
	var tasks: Array = lvl.get("tasks", [])
	if tasks.is_empty():
		return false
	for t in tasks:
		var tid: String = t.get("id", "")
		if not completed_task_ids.has(tid):
			return false
	return true

func is_level_completed(level_id: String) -> bool:
	return are_all_level_tasks_completed(level_id)

func reset_for_replay(keep_unlocked: bool = false) -> void:
	completed_task_ids.clear()
	for lvl in levels_data:
		lvl["completed"] = false
		var tasks: Array = lvl.get("tasks", [])
		for t in tasks:
			t["completed"] = false
			t["player_submitted_value"] = null
	if not keep_unlocked:
		unlocked_level_ids.clear()
		if levels_data.size() > 0:
			unlocked_level_ids.append(levels_data[0].get("id", "LVL_01"))
	update_unlock_states()

func check_and_update_level_completion(level_id: String) -> void:
	var lvl: Dictionary = get_level(level_id)
	if not lvl.is_empty():
		lvl["completed"] = are_all_level_tasks_completed(level_id)

func update_unlock_states() -> void:
	# STRICT RULE: A mission cannot unlock until all mandatory tasks of the previous mission are completed.
	for i in range(levels_data.size()):
		var current_lvl: Dictionary = levels_data[i]
		var current_id: String = current_lvl.get("id", "")
		
		if i == 0:
			current_lvl["unlocked"] = true
			if not unlocked_level_ids.has(current_id):
				unlocked_level_ids.append(current_id)
		else:
			var prev_lvl: Dictionary = levels_data[i - 1]
			var prev_id: String = prev_lvl.get("id", "")
			var prev_completed: bool = are_all_level_tasks_completed(prev_id)
			
			current_lvl["unlocked"] = prev_completed
			if prev_completed:
				if not unlocked_level_ids.has(current_id):
					unlocked_level_ids.append(current_id)
			else:
				unlocked_level_ids.erase(current_id)

func get_completed_tasks_count() -> int:
	return completed_task_ids.size()

func get_total_tasks_count() -> int:
	var total: int = 0
	for lvl in levels_data:
		total += lvl.get("tasks", []).size()
	return total

func serialize() -> Dictionary:
	return {
		"unlocked_level_ids": unlocked_level_ids,
		"completed_task_ids": completed_task_ids
	}

func deserialize(data: Dictionary) -> void:
	if data.has("completed_task_ids"):
		completed_task_ids = data["completed_task_ids"]
	if data.has("unlocked_level_ids"):
		var raw_unlocked: Array = data["unlocked_level_ids"]
		unlocked_level_ids.clear()
		for item in raw_unlocked:
			unlocked_level_ids.append(str(item))
	# Sync with internal levels
	for lvl in levels_data:
		var tasks: Array = lvl.get("tasks", [])
		for t in tasks:
			var tid: String = t.get("id", "")
			if completed_task_ids.has(tid):
				t["completed"] = true
				t["player_submitted_value"] = completed_task_ids[tid].get("player_value")
	update_unlock_states()
