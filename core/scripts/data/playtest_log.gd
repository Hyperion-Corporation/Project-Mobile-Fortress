class_name PlaytestLog
extends RefCounted
## DT7 playtest session logger. Source of truth: user://playtest_sessions.json.
## Sync maps onto PlaytestNotesView's dashboard JSON — event-triggered, not telemetry.

const SCHEMA_VERSION := 1
const STORE_PATH := "user://playtest_sessions.json"
const DASHBOARD_REL := "../docs/website/public/dashboard-data/playtest_sessions.json"

static var open_session_id: String = ""
static var tester_name: String = "tester"


static func default_store() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"sessions": [],
	}


static func default_dashboard() -> Dictionary:
	return {
		"gate": "VS10",
		"sessions_required": 2,
		"sessions": [],
		"gate_decision": null,
	}


static func load_store() -> Dictionary:
	var parsed: Variant = OfflinePersistence.read_json(STORE_PATH)
	if parsed is Dictionary:
		var store: Dictionary = parsed
		if not store.has("sessions") or not store["sessions"] is Array:
			store["sessions"] = []
		return store
	return default_store()


static func save_store(store: Dictionary) -> bool:
	var payload := store.duplicate(true)
	payload["schema_version"] = SCHEMA_VERSION
	return OfflinePersistence.write_json(STORE_PATH, payload)


static func ensure_open_session() -> Dictionary:
	var store := load_store()
	var sessions: Array = store["sessions"]
	if open_session_id != "":
		for session in sessions:
			if session is Dictionary and str(session.get("id", "")) == open_session_id:
				return session
	var started := int(Time.get_unix_time_from_system())
	var session := {
		# Dashboard sync merges by id; seconds alone can collide when a tester
		# closes and opens sessions rapidly.
		"id": "sess_%d_%d" % [started, Time.get_ticks_usec()],
		"started_unix": started,
		"date": Time.get_date_string_from_system(),
		"tester": tester_name,
		"platform": OS.get_name(),
		"build_commit": git_commit(),
		"hard_criteria_pass": false,
		"art_criteria_pass": false,
		"verdict": "needs_work",
		"notes": "",
		"events": [],
	}
	sessions.append(session)
	store["sessions"] = sessions
	open_session_id = str(session["id"])
	save_store(store)
	return session


static func mark_event(label: String, extra: Dictionary = {}) -> Dictionary:
	ensure_open_session()
	var store := load_store()
	var event := {
		"unix": int(Time.get_unix_time_from_system()),
		"iso": Time.get_datetime_string_from_system(true),
		"label": label,
		"note": str(extra.get("note", "")),
		"phase": str(extra.get("phase", "")),
		"wave": int(extra.get("wave", -1)),
	}
	for session in store["sessions"]:
		if session is Dictionary and str(session.get("id", "")) == open_session_id:
			var events: Array = session.get("events", [])
			if not events is Array:
				events = []
			events.append(event)
			session["events"] = events
			session["tester"] = tester_name
			break
	save_store(store)
	return event


static func set_session_meta(fields: Dictionary) -> void:
	if fields.is_empty():
		return
	ensure_open_session()
	var store := load_store()
	for session in store["sessions"]:
		if session is Dictionary and str(session.get("id", "")) == open_session_id:
			for key in fields.keys():
				session[key] = fields[key]
			break
	save_store(store)


static func note_run_ended(result: Dictionary) -> void:
	if open_session_id == "":
		return
	var victory := bool(result.get("victory", false))
	var reason := str(result.get("reason", ""))
	mark_event("run_ended", {
		"note": ("%s — %s" % ["victory" if victory else "defeat", reason]).strip_edges(),
		"wave": int(result.get("wave", -1)),
		"phase": "RESULT",
	})


static func git_commit() -> String:
	var core := ProjectSettings.globalize_path("res://")
	var out: Array = []
	var code := OS.execute("git", PackedStringArray(["-C", core, "rev-parse", "--short", "HEAD"]), out, true, false)
	if code == 0 and not out.is_empty():
		var sha := str(out[0]).strip_edges()
		if sha != "":
			return sha
	return "unknown"


static func dashboard_session(session: Dictionary) -> Dictionary:
	var notes := str(session.get("notes", ""))
	var lines: PackedStringArray = PackedStringArray()
	if notes != "":
		lines.append(notes)
	var events: Variant = session.get("events", [])
	if events is Array:
		for event in events:
			if not event is Dictionary:
				continue
			var line := str(event.get("iso", "")) + " — " + str(event.get("label", "mark"))
			var phase := str(event.get("phase", ""))
			if phase != "":
				line += " [" + phase + "]"
			var extra := str(event.get("note", ""))
			if extra != "":
				line += " · " + extra
			lines.append(line)
	var verdict := str(session.get("verdict", "needs_work"))
	if verdict != "shows_promise" and verdict != "needs_work" and verdict != "no":
		verdict = "needs_work"
	return {
		"id": str(session.get("id", "")),
		"date": str(session.get("date", "")),
		"tester": str(session.get("tester", "tester")),
		"platform": str(session.get("platform", "")),
		"build_commit": str(session.get("build_commit", "unknown")),
		"hard_criteria_pass": bool(session.get("hard_criteria_pass", false)),
		"art_criteria_pass": bool(session.get("art_criteria_pass", false)),
		"verdict": verdict,
		"notes": "\n".join(lines),
	}


static func merge_dashboard(src_store: Dictionary, dest: Dictionary) -> Dictionary:
	var out := dest.duplicate(true)
	if not out.has("gate"):
		out["gate"] = "VS10"
	if not out.has("sessions_required"):
		out["sessions_required"] = 2
	if not out.has("gate_decision"):
		out["gate_decision"] = null
	var dest_sessions: Array = []
	if out.get("sessions", null) is Array:
		dest_sessions = (out["sessions"] as Array).duplicate()
	var index_by_id := {}
	for i in dest_sessions.size():
		var existing: Variant = dest_sessions[i]
		if existing is Dictionary and str(existing.get("id", "")) != "":
			index_by_id[str(existing["id"])] = i
	var incoming: Array = []
	if src_store.get("sessions", null) is Array:
		incoming = src_store["sessions"]
	for session in incoming:
		if not session is Dictionary:
			continue
		var mapped: Dictionary = dashboard_session(session)
		var sid := str(mapped.get("id", ""))
		if sid != "" and index_by_id.has(sid):
			dest_sessions[int(index_by_id[sid])] = mapped
		else:
			dest_sessions.append(mapped)
			if sid != "":
				index_by_id[sid] = dest_sessions.size() - 1
	out["sessions"] = dest_sessions
	return out


static func discover_dashboard_path() -> String:
	var core := ProjectSettings.globalize_path("res://")
	var dest := core.path_join(DASHBOARD_REL).simplify_path()
	if FileAccess.file_exists(dest):
		return dest
	var parent := dest.get_base_dir()
	if DirAccess.dir_exists_absolute(parent):
		return dest
	return ""


static func write_absolute_json(path: String, data: Variant) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("PlaytestLog: cannot write %s" % path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


static func read_absolute_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)


static func sync_to_dashboard(dest_override: String = "") -> Dictionary:
	var dest := dest_override
	if dest == "":
		dest = discover_dashboard_path()
	if dest == "":
		var exported := export_copy()
		return {
			"ok": exported != "",
			"mode": "export",
			"path": exported,
			"message": "No website checkout — exported for scripts/sync_playtest_session.sh",
		}
	var existing: Variant = read_absolute_json(dest)
	var dest_data: Dictionary = default_dashboard()
	if existing is Dictionary:
		dest_data = existing
	var merged := merge_dashboard(load_store(), dest_data)
	if not write_absolute_json(dest, merged):
		return {"ok": false, "mode": "desktop", "path": dest, "message": "write failed"}
	return {"ok": true, "mode": "desktop", "path": dest, "message": "synced %d session(s)" % (merged["sessions"] as Array).size()}


static func export_copy() -> String:
	var store := load_store()
	var dest := ""
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads != "":
		dest = downloads.path_join("playtest_sessions.json")
	else:
		dest = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("mf_playtest_sessions.json")
	if dest == "" or dest.ends_with("/"):
		dest = ProjectSettings.globalize_path("user://playtest_sessions_export.json")
	if write_absolute_json(dest, store):
		return dest
	var fallback := ProjectSettings.globalize_path("user://playtest_sessions_export.json")
	if write_absolute_json(fallback, store):
		return fallback
	return ""
