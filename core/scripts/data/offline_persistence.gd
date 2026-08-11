class_name OfflinePersistence
extends RefCounted
## VS8 offline campaign I/O: run results JSON, append-only history, FlatBuffers snapshot bytes.
## All paths under user:// (device-local; no network).

const SCHEMA_VERSION := 1
const RESULTS_PATH := "user://last_run_results.json"
const HISTORY_PATH := "user://run_history.json"
const SNAPSHOT_PATH := "user://mf_slice0_snapshot.bin"
const CLASSIC_SAVE_PATH := "user://mobile_fortress_slice0.json"
const MAX_HISTORY := 20


static func write_json(path: String, data: Variant) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("OfflinePersistence: cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)


static func write_results(result: Dictionary) -> bool:
	var payload := result.duplicate(true)
	if not payload.has("schema_version"):
		payload["schema_version"] = SCHEMA_VERSION
	if not payload.has("timestamp_unix"):
		payload["timestamp_unix"] = Time.get_unix_time_from_system()
	return write_json(RESULTS_PATH, payload)


static func read_results() -> Dictionary:
	var parsed: Variant = read_json(RESULTS_PATH)
	if parsed is Dictionary:
		return parsed
	return {}


static func has_results() -> bool:
	return FileAccess.file_exists(RESULTS_PATH)


static func append_history(result: Dictionary) -> bool:
	var history: Array = []
	var existing: Variant = read_json(HISTORY_PATH)
	if existing is Dictionary and existing.has("runs") and existing["runs"] is Array:
		history = (existing["runs"] as Array).duplicate()
	elif existing is Array:
		history = existing.duplicate()
	var entry := result.duplicate(true)
	if not entry.has("schema_version"):
		entry["schema_version"] = SCHEMA_VERSION
	if not entry.has("timestamp_unix"):
		entry["timestamp_unix"] = Time.get_unix_time_from_system()
	history.append(entry)
	while history.size() > MAX_HISTORY:
		history.pop_front()
	return write_json(HISTORY_PATH, {"schema_version": SCHEMA_VERSION, "runs": history})


static func read_history() -> Array:
	var existing: Variant = read_json(HISTORY_PATH)
	if existing is Dictionary and existing.get("runs", null) is Array:
		return existing["runs"]
	if existing is Array:
		return existing
	return []


static func write_snapshot(bytes: PackedByteArray) -> bool:
	if bytes.is_empty():
		return false
	var f := FileAccess.open(SNAPSHOT_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("OfflinePersistence: cannot write snapshot")
		return false
	f.store_buffer(bytes)
	f.close()
	return true


static func read_snapshot() -> PackedByteArray:
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		return PackedByteArray()
	var f := FileAccess.open(SNAPSHOT_PATH, FileAccess.READ)
	if f == null:
		return PackedByteArray()
	var bytes: PackedByteArray = f.get_buffer(f.get_length())
	f.close()
	return bytes


static func has_snapshot() -> bool:
	return FileAccess.file_exists(SNAPSHOT_PATH) and FileAccess.get_file_as_bytes(SNAPSHOT_PATH).size() > 0


static func format_results_summary(result: Dictionary) -> String:
	if result.is_empty():
		return "No prior offline run recorded."
	var title := "Victory" if bool(result.get("victory", false)) else "Defeat"
	var reason: String = str(result.get("reason", ""))
	var kills: int = int(result.get("enemies_killed", 0))
	var placed: int = int(result.get("units_placed", 0))
	var outposts: int = int(result.get("outposts_lost", 0))
	var backend: String = str(result.get("sim", "unknown"))
	return "%s — %s\nKills %d · Placed %d · Outposts lost %d · sim:%s" % [
		title, reason, kills, placed, outposts, backend
	]
