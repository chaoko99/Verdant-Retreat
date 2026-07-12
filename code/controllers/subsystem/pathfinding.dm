// ==============================================================================
// PATHFINDING SUBSYSTEM
// ==============================================================================
// A globally accessible A* pathfinding service, computed by verdant_native
// over its grid mirror on a worker thread. To use from anywhere in the code:
//      var/list/path = A_Star(mob, start_turf, end_turf)
// The await call sleeps the calling proc, so only request paths from contexts
// that may sleep (AI think handlers are INVOKE_ASYNC'd and qualify).

SUBSYSTEM_DEF(pathfinding)
	name = "Pathfinding"
	priority = SS_PRIORITY_AI
	init_order = INIT_ORDER_AI
	runlevels = RUNLEVELS_DEFAULT
	flags = SS_NO_FIRE // on-demand service; nothing to tick

	var/list/patrol_nodes
	var/paths_served = 0
	var/paths_failed = 0

/datum/controller/subsystem/pathfinding/Initialize()
	NEW_SS_GLOBAL(SSpathfinding)
	patrol_nodes = new // Manually populated by placing patrol points on the map; unused is fine.
	..()

/datum/controller/subsystem/pathfinding/proc/FindPath(mob/living/mover, turf/start, turf/end)
	if(!(VN_OK && SSnative?.mirror_loaded))
		return null
	start = get_turf(start)
	end = get_turf(end)
	if(!start || !end)
		return null

	var/prof = mover ? mover.vn_path_profile() : 0
	var/raw
	if(start.z == end.z && get_dist(start, end) <= 30)
		raw = vn_path_find_sync(start.x, start.y, start.z, end.x, end.y, end.z, 0, prof)
	else
		raw = vn_path_find(start.x, start.y, start.z, end.x, end.y, end.z, 0, prof)
	if(!islist(raw))
		vn_check_result(raw, "path_find")
		paths_failed++
		return null
	if(!length(raw))
		return null // no route
	var/list/path = list()
	for(var/i = 1, i + 2 <= length(raw), i += 3)
		var/turf/T = locate(raw[i], raw[i + 1], raw[i + 2])
		if(!T)
			paths_failed++
			return null
		path += T
	paths_served++
	return path

/datum/controller/subsystem/pathfinding/stat_entry(msg)
	msg += "served:[paths_served]|failed:[paths_failed]"
	return ..()
