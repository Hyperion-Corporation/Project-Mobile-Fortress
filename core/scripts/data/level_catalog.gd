class_name LevelCatalog
extends RefCounted
## Dual-front level list for G5. Skips leftover single-front templates (no landCount/seaCount).

const LEVELS_DIR := "res://assets/levels"
const DEFAULT_PATH := "res://assets/levels/slice0_dual_front.json"
const DEFAULT_ID := "slice0_dual_front"


static func list_levels() -> Array:
	var out: Array = []
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			var path := LEVELS_DIR.path_join(name)
			var entry := parse_level(path)
			if not entry.is_empty():
				out.append(entry)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return out


static func parse_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	var waves: Variant = data.get("waves", [])
	if not waves is Array or (waves as Array).is_empty():
		return {}
	var first: Variant = (waves as Array)[0]
	if not first is Dictionary:
		return {}
	if not first.has("landCount") and not first.has("seaCount"):
		return {}
	return {
		"id": str(data.get("id", path.get_file().get_basename())),
		"displayName": str(data.get("displayName", data.get("id", path))),
		"path": path,
		"wave_count": (waves as Array).size(),
		"build_phase": float(data.get("buildPhaseSeconds", 40.0)),
		"victory_time": float(data.get("victoryTimeSeconds", 55.0)),
	}


static func find_by_id(level_id: String) -> Dictionary:
	for entry in list_levels():
		if str(entry.get("id", "")) == level_id:
			return entry
	return {}


static func find_by_path(path: String) -> Dictionary:
	for entry in list_levels():
		if str(entry.get("path", "")) == path:
			return entry
	return parse_level(path)
