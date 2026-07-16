SUBSYSTEM_DEF(lighting)
	name = "Lighting"
	wait = 0
	init_order = INIT_ORDER_LIGHTING
	flags = SS_TICKER
	priority = FIRE_PRIORITY_DEFAULT
	var/static/list/sources_queue = list() // List of lighting sources queued for update.
	var/static/list/corners_queue = list() // List of lighting corners queued for update.
	var/static/list/objects_queue = list() // List of lighting objects queued for update.
	processing_flag = PROCESSING_LIGHTING

	var/static/vn_next_light_id = 0 // Counter for /datum/light_source.vn_light_id.
	var/static/list/vn_light_events = list() // Flat ADD/REPLACE/REMOVE event buffer, flushed to vn_light_tick_begin() each fire().

/datum/controller/subsystem/lighting/stat_entry()
	..("L:[length(sources_queue)]|C:[length(corners_queue)]|O:[length(objects_queue)]")


/datum/controller/subsystem/lighting/Initialize(timeofday)
	if(!initialized)
		if (CONFIG_GET(flag/starlight))
			for(var/I in GLOB.sortedAreas)
				var/area/A = I
				if (A.dynamic_lighting == DYNAMIC_LIGHTING_IFSTARLIGHT)
					A.luminosity = 0

		create_all_lighting_objects()
		initialized = TRUE

	fire(FALSE, TRUE)

	return ..()

// Full rebuild: native contributions live only in corner accumulators and native's
// private per-source memory, so leaving native mode zeroes every corner and
// re-applies every source through the DM path from scratch.
/datum/controller/subsystem/lighting/proc/vn_light_disable_native()
	GLOB.vn_lighting_native = FALSE
	vn_light_events = list()
	if (VN_OK)
		vn_light_reset()
	for (var/key in GLOB.vn_light_corners)
		var/datum/lighting_corner/C = GLOB.vn_light_corners[key]
		if (C.lum_r || C.lum_g || C.lum_b)
			C.update_lumcount(-C.lum_r, -C.lum_g, -C.lum_b)
	for (var/datum/light_source/L as anything in GLOB.all_light_sources)
		if (L.effect_str)
			for (var/datum/lighting_corner/C as anything in L.effect_str)
				LAZYREMOVE(C.affecting, L)
			L.effect_str = null
		L.vn_native_applied = FALSE
		L.force_update()

/datum/controller/subsystem/lighting/proc/apply_light_collect(list/res)
	var/cur = 1
	var/n = res[cur++]
	for (var/i in 1 to n)
		var/id = res[cur++]
		var/dr = res[cur++]
		var/dg = res[cur++]
		var/db = res[cur++]
		var/datum/lighting_corner/C = GLOB.vn_light_corners["[id]"]
		if (C)
			C.update_lumcount(dr, dg, db)

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	MC_SPLIT_TICK_INIT(3)
	if(!init_tick_checks)
		MC_SPLIT_TICK

	var/light_native = VN_OK && GLOB.vn_lighting_native
	if (light_native)
		var/res = vn_light_tick_collect()
		if (islist(res))
			if (length(res))
				apply_light_collect(res)
		else if (!vn_check_result(res, "light_tick_collect"))
			vn_light_disable_native()
			light_native = FALSE

	var/list/queue = sources_queue
	var/i = 0
	for (i in 1 to length(queue))
		var/datum/light_source/L = queue[i]

		L.update_corners()

		L.needs_update = LIGHTING_NO_UPDATE

		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)
		i = 0

	if(!init_tick_checks)
		MC_SPLIT_TICK

	queue = corners_queue
	for (i in 1 to length(queue))
		var/datum/lighting_corner/C = queue[i]

		C.update_objects()
		C.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)
		i = 0


	if(!init_tick_checks)
		MC_SPLIT_TICK

	queue = objects_queue
	for (i in 1 to length(queue))
		var/atom/movable/lighting_object/O = queue[i]

		if (QDELETED(O))
			continue

		O.update()
		O.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		queue.Cut(1, i+1)

	if (light_native && length(vn_light_events))
		var/res = vn_light_tick_begin(vn_light_events)
		if (res == "busy" || (istext(res) && findtext(res, "ERR:queue:") == 1)) // previous tick in flight; keep the buffer and retry next fire
			return
		if (vn_check_result(res, "light_tick_begin"))
			vn_light_events = list()
		else
			vn_light_disable_native()


/datum/controller/subsystem/lighting/Recover()
	initialized = SSlighting.initialized
	..()
