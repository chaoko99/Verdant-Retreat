/*
 ██▓     ██▓  █████   █    ██  ██▓▓█████▄   ██████
▓██▒    ▓██▒▒██▓  ██▒ ██  ▓██▒▓██▒▒██▀ ██▌▒██    ▒
▒██░    ▒██▒▒██▒  ██░▓██  ▒██░▒██▒░██   █▌░ ▓██▄
▒██░    ░██░░██  █▀ ░▓▓█  ░██░░██░░▓█▄   ▌  ▒   ██▒
░██████▒░██░░▒███▒█▄ ▒▒█████▓ ░██░░▒████▓ ▒██████▒▒
░ ▒░▓  ░░▓  ░░ ▒▒░ ▒ ░▒▓▒ ▒ ▒ ░▓   ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░
░ ░ ▒  ░ ▒ ░ ░ ▒░  ░ ░░▒░ ░ ░  ▒ ░ ░ ▒  ▒ ░ ░▒  ░ ░
  ░ ░    ▒ ░   ░   ░  ░░░ ░ ░  ▒ ░ ░ ░  ░ ░  ░  ░
	░  ░ ░      ░       ░      ░     ░          ░
								   ░
									- By Plasmatik

================
This subsystem is used to simulate simple fluid dynamics using cellular automata in a manner similar to Dwarf Fortress.

Many variables are kept on turf.cell because it is faster than using some abstract datastructure. It also makes it easy to check those variables on turfs to make cell do things.
Fluid types are checked in sequence based on the fluid_volume and new_volume associative lists on turfs' liquid datums. There is a global list of fluid types in _defines/liquid.dm  for turf initialization to refer to,
So that turf/Initialize() doesn't need to be altered when / if new fluid types get added.

I wrote all of this myself from scratch, and would prefer if this particular system remained outside of open source codebases. Please do not publicly host this code without asking me.
================
*/

PROCESSING_SUBSYSTEM_DEF(liquid)
	name = "liquid"
	priority = SS_PRIORITY_LIQUID
	init_order = INIT_ORDER_LIQUID
	wait = 1 // Needs to run every tick to avoid synchronization issues with the disjointed set implementation, but shouldn't hurt performance with all the optimizations
	runlevels = RUNLEVELS_DEFAULT
	flags = SS_KEEP_TIMING
	var/list/liquid_sources
	var/list/liquid_sinks
	var/remove_cells_timer = 0
	var/list/cell_index
	var/list/sleeping_cells
	var/list/dirty

	var/list/process_queue
	var/list/reset_queue

	var/phase = 1
	var/prcs_idx = 1
	can_fire = FALSE

	// State validation tracking
	var/list/cells_in_processing


	// Resource management
	var/max_cells_per_tick = 200 // Maximum cells to process per tick before splitting


/datum/controller/subsystem/processing/liquid/Initialize()
	. = ..()
	NEW_SS_GLOBAL(SSliquid)

	liquid_sources = new
	liquid_sinks = new
	cell_index = new
	sleeping_cells = new
	process_queue = new
	reset_queue = new
	dirty = new
	cells_in_processing = new

	GLOB.liquid_registry.refresh_registry()

	for(var/turf/T in world) // You can't stop me from doing this. No one can stop me from doing this. Mwahahaha
		if(!T.cell)
			T.cell = new /cell(T)
			T.cell.InitLiquids()

/datum/controller/subsystem/processing/liquid/fire(resumed = 0, no_mc_tick = FALSE)
	MC_SPLIT_TICK_INIT(3)

	// Phase 1: Populate process_queue and reset_queue
	if(phase == 1)
		// Clear processing state tracking from previous cycle
		cells_in_processing.len = 0

		for(var/i = prcs_idx, i <= length(cell_index), i++)
			var/turf/T = get_key_by_index(cell_index, i)
			if(!T) continue

			dirty += T

			// Handle sleeping cells with proper state validation
			if(sleeping_cells[T])
				sleeping_cells -= T

			process_queue += T
			if(T.cell.fluid_flags & FLUID_MOVED)
				reset_queue += T

			prcs_idx++

			if(no_mc_tick)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				return

		if(prcs_idx > length(cell_index))
			prcs_idx = 1
			phase = 2

		if(!no_mc_tick)
			MC_SPLIT_TICK

	// Phase 2: Process cells in the queue
	if(phase == 2)
		while(length(process_queue))
			var/turf/cell = pick_n_take(process_queue)

			// Process the cell
			cells_in_processing += cell
			update_cell(cell)

			// Remove from processing tracking
			cells_in_processing -= cell

			prcs_idx++

			if(no_mc_tick)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				return

		if(prcs_idx > length(process_queue))
			prcs_idx = 1
			phase = 3

		if(!no_mc_tick)
			MC_SPLIT_TICK

	// Phase 3: Commit buffered changes and process pressure flow
	if(phase == 3)
		for(var/turf/T as anything in cell_index)
			if(T.cell.new_fluidsum == 0)
				continue

			for(var/datum/liquid/fluid in T.cell.fluid_volume)
				T.cell.fluid_volume[fluid] += T.cell.new_volume[fluid]
				T.cell.new_volume[fluid] = 0
			T.cell.new_fluidsum = 0

		process_pressure_flow()

		for(var/turf/T as anything in cell_index)
			update_fluidsum(T, FALSE)

		if(!no_mc_tick)
			MC_SPLIT_TICK

		phase = 4

	// Phase 4: Reset fluid flags and finalize updates
	if(phase == 4)
		update_pools()

		// Process continuous liquid behaviors for mobs standing in liquid pools
		GLOB.pool_manager.process_continuous_behaviors()

		// Process floor chemical reactions if dynamic liquids are enabled
		GLOB.pool_manager.process_floor_reactions()

		// Simple reset queue processing
		for(var/turf/T as anything in reset_queue)
			T.cell.fluid_flags &= ~FLUID_MOVED
		reset_queue.len = 0

		for(var/turf/T as anything in cell_index)
			update_cell_image(T)

		remove_cells_timer++
		if(remove_cells_timer >= 50)
			remove_unwanted_cells()
			// Clean up empty pools less frequently to allow pools to persist
			GLOB.pool_manager.cleanup_empty_pools()
			remove_cells_timer = 0

		// Update processing time for debug manager

		phase = 1
		if(!no_mc_tick)
			MC_SPLIT_TICK

/datum/controller/subsystem/processing/liquid/proc/update_pools()
	var/list/dirty = list()
	for (var/turf/T as anything in cell_index)
		// Include turfs that moved OR have significant liquid (for static pools)
		if (T.cell.fluid_flags & FLUID_MOVED || T.cell.fluidsum >= MIN_FLUID_VOLUME)
			dirty |= T

	// Add sleeping cells to the dirty list to keep pool_manager aware of them
	for(var/turf/T as anything in sleeping_cells)
		dirty |= T

	GLOB.pool_manager.update_pools(dirty)

/datum/controller/subsystem/processing/liquid/proc/get_pool(turf/T)
	return GLOB.pool_manager.get_pool(T)

/datum/controller/subsystem/processing/liquid/proc/get_pool_avg(list/pool)
	return GLOB.pool_manager.get_pool_avg_fluid(pool)

/datum/controller/subsystem/processing/liquid/proc/spread_shock(mob/living/carbon/C, turf/T, shock_damage, def_zone, siemens_coeff)
	return GLOB.liquid_registry.execute_flag_behavior(FLUID_CONDUCTIVE, "conduct_shock", C, T, shock_damage, def_zone, siemens_coeff)


/datum/controller/subsystem/processing/liquid/proc/remove_unwanted_cells()
	for(var/turf/T as anything in cell_index)
		if(!can_process_fluid(T))
			T.cell.fluid_flags &= ~FLUID_MOVED
			cell_index -= T
			if(get_fluid_level(T) > FLUID_EMPTY && !(T in sleeping_cells))
				sleeping_cells[T] = TRUE

/datum/controller/subsystem/processing/liquid/proc/can_process_fluid(turf/T) as num
	if(!T?.cell)
		return FALSE
	return isopenspace(T) && get_fluid_level(T) > FLUID_EMPTY || !isopenspace(T) && (T.cell.fluid_flags & FLUID_MOVED || T.cell.new_fluidsum > MIN_FLUID_VOLUME)




/datum/controller/subsystem/processing/liquid/proc/update_cell(turf/T)
	if(!T?.cell)
		return FALSE

	// Process each fluid type separately
	for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
		var/current_amount = T.cell.fluid_volume[fluid]
		if(current_amount <= 0)
			continue

		// Reset pressure mask for this turf
		T.cell.pressure_mask = 0

		// Step 1: Gravity (Vertical Drop)
		var/turf/down_turf = GetBelow(T)
		if(down_turf && !down_turf.blocks_flow() && !isopenspace(T))
			var/space_below = max(0, 100 - GET_TOTAL_FLUID(down_turf))
			var/drop_amount = min(current_amount, space_below)

			if(drop_amount > 0)
				T.cell.new_volume[fluid] -= drop_amount
				var/datum/liquid/target_fluid = GetLiquidInstance(fluid, down_turf, TRUE)
				down_turf.cell.new_volume[target_fluid] += drop_amount
				update_fluidsum(down_turf, TRUE)
				cell_index[down_turf] = TRUE
				down_turf.cell.fluid_flags |= FLUID_MOVED
				current_amount -= drop_amount

		// Step 2: Lateral Flow (Neighbor Averaging with Remainder Handling)
		if(current_amount > 0)
			var/list/low_neighbors = list()
			var/turf/preferred_neighbor = null

			// Check for flow direction preference
			if(T.cell.flow_dir)
				var/turf/flow_target = get_step(T, T.cell.flow_dir)
				if(flow_target && !flow_target.density && !flow_target.blocks_flow() && !T.LinkBlocked(T, flow_target))
					if(GET_TOTAL_FLUID(flow_target) < current_amount)
						preferred_neighbor = flow_target

			// Find neighbors with less total fluid
			for(var/direction in GLOB.cardinals)
				var/turf/neighbor = get_step(T, direction)
				if(!neighbor || neighbor.density || neighbor.blocks_flow())
					continue
				if(T.LinkBlocked(T, neighbor))
					continue

				var/neighbor_total = GET_TOTAL_FLUID(neighbor)
				if(neighbor_total < current_amount)
					low_neighbors += neighbor

			if(length(low_neighbors) > 0)
				// If we have a preferred flow direction, give it priority
				if(preferred_neighbor && (preferred_neighbor in low_neighbors))
					var/neighbor_current = GET_TOTAL_FLUID(preferred_neighbor)
					var/flow = ((current_amount - neighbor_current) * 6) / 10

					if(flow > 0)
						flow = min(flow, current_amount)
						T.cell.new_volume[fluid] -= flow
						var/datum/liquid/target_fluid = GetLiquidInstance(fluid, preferred_neighbor, TRUE)
						preferred_neighbor.cell.new_volume[target_fluid] += flow

						T.cell.pressure_mask |= T.cell.flow_dir

						update_fluidsum(preferred_neighbor, TRUE)
						cell_index[preferred_neighbor] = TRUE
						preferred_neighbor.cell.fluid_flags |= FLUID_MOVED
						current_amount -= flow

				// Calculate total fluid across all tiles
				var/total_fluid = current_amount
				for(var/turf/neighbor as anything in low_neighbors)
					total_fluid += GET_TOTAL_FLUID(neighbor)

				var/tile_count = length(low_neighbors) + 1
				var/target_level = round(total_fluid / tile_count)
				var/remainder = total_fluid % tile_count

				// Distribute to each neighbor
				for(var/turf/neighbor as anything in low_neighbors)
					var/neighbor_current = GET_TOTAL_FLUID(neighbor)
					var/flow = target_level - neighbor_current

					if(flow > 0)
						flow = min(flow, current_amount)
						T.cell.new_volume[fluid] -= flow
						var/datum/liquid/target_fluid = GetLiquidInstance(fluid, neighbor, TRUE)
						neighbor.cell.new_volume[target_fluid] += flow

						var/flow_dir = get_dir(T, neighbor)
						T.cell.pressure_mask |= flow_dir

						update_fluidsum(neighbor, TRUE)
						cell_index[neighbor] = TRUE
						neighbor.cell.fluid_flags |= FLUID_MOVED
						current_amount -= flow

				// Restore remainder to source
				if(remainder > 0)
					T.cell.new_volume[fluid] += remainder

		update_fluidsum(T, TRUE)
		T.cell.fluid_flags |= FLUID_MOVED
		cell_index[T] = TRUE


/datum/controller/subsystem/processing/liquid/proc/handle_flow_interaction(turf/source, turf/target, transfer_amount, is_pressure = FALSE, list/pressure_path)
	var/flow_dir
	if(is_pressure)
		flow_dir = get_dir(source, target)
	else
		var/mask = source.cell.pressure_mask
		if(mask == 0)
			return

		if(mask == NORTH || mask == SOUTH || mask == EAST || mask == WEST)
			flow_dir = mask
		else
			flow_dir = get_dir(source, target)

	if(!flow_dir)
		return

	for(var/atom/movable/AM in target)
		if(!ismob(AM) && !isitem(AM))
			continue

		if(AM.anchored)
			continue

		var/threshold_strong = is_pressure ? 20 : 25
		var/threshold_moderate = 15

		var/throw_range = is_pressure ? min(4, round(transfer_amount / 15)) : min(3, round(transfer_amount / 20))
		var/throw_speed = is_pressure ? min(4, round(transfer_amount / 10)) : min(3, round(transfer_amount / 15))

		var/throw_dir = flow_dir
		if(prob(20))
			throw_dir = turn(flow_dir, pick(45, -45))

		if(isliving(AM))
			var/mob/living/L = AM

			if(transfer_amount >= threshold_strong)
				if(is_pressure)
					L.Knockdown(30)
					to_chat(L, span_danger("A surge of pressurized liquid blasts into you with tremendous force!"))
				else
					L.Knockdown(20)
					to_chat(L, span_warning("The rushing liquid crashes into you and sweeps you away!"))
			else if(transfer_amount >= threshold_moderate && is_pressure)
				L.Knockdown(10)
				to_chat(L, span_warning("The pressurized liquid strikes you with considerable force!"))
			else
				L.Stun(5)
				if(is_pressure)
					to_chat(L, span_notice("The flowing liquid pushes against you!"))
				else
					to_chat(L, span_notice("The rushing liquid nearly knocks you off your feet!"))

		if(throw_range > 0)
			var/turf/target_turf = get_edge_target_turf(target, throw_dir)
			AM.throw_at(target_turf, throw_range, throw_speed)


/datum/controller/subsystem/processing/liquid/proc/GetLiquidInstance(datum/liquid/fluid, turf/T, buffered = FALSE) as /datum
	if(buffered)
		return locate(fluid.type) in T.cell.new_volume
	else
		return locate(fluid.type) in T.cell.fluid_volume


/datum/controller/subsystem/processing/liquid/proc/process_sources()
	for(var/turf/T as anything in liquid_sources)
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			T.cell.fluid_volume[fluid] += min(MAX_FLUID_VOLUME, T.cell.production_rate)
			update_cell(T)

/datum/controller/subsystem/processing/liquid/proc/process_sinks()
	for(var/turf/T as anything in liquid_sinks)
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			T.cell.fluid_volume[fluid] = max(T.cell.fluid_volume[fluid] - T.cell.absorption_rate, 0)
			update_cell(T)

/datum/controller/subsystem/processing/liquid/proc/update_fluidsum(turf/T, var/buffered = FALSE)
	var/sum = 0
	if(buffered)
		for(var/datum/liquid/fluid as anything in T.cell.new_volume)
			sum += T.cell.new_volume[fluid]
		T.cell.new_fluidsum = sum
	else
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			sum += T.cell.fluid_volume[fluid]
		T.cell.fluidsum = sum
		T.cell.last_fluid_level = get_fluid_level(T)

// Update everything version, for calling during init if necessary
/datum/controller/subsystem/processing/liquid/proc/update_fluidsums()
	for(var/turf/T as anything in cell_index)
		var/sum = 0
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			sum += T.cell.fluid_volume[fluid]
		T.cell.fluidsum = sum
		T.cell.last_fluid_level = get_fluid_level(T)

/datum/controller/subsystem/processing/liquid/proc/get_fluidsums(turf/T) as num
	var/sum = 0
	for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
		sum += T.cell.fluid_volume[fluid]
	return sum

/datum/controller/subsystem/processing/liquid/proc/get_fluid_level(turf/T) as num
	if(!istype(T) || !T.cell) return FLUID_EMPTY
	var/fluidsum = T.cell.fluidsum

	switch(fluidsum)
		if(0)
			return FLUID_EMPTY
		if(1 to 20)
			return FLUID_VERY_LOW
		if(21 to 30)
			return FLUID_LOW
		if(31 to 40)
			return FLUID_MEDIUM
		if(41 to 55)
			return FLUID_HIGH
		if(56 to 60)
			return FLUID_VERY_HIGH
		if(61 to 95)
			return FLUID_FULL
		else
			return FLUID_OVERFLOW

/turf/liquid_source
	name = "Liquid source"

/turf/liquid_source/Initialize()
	. = ..()
	SSliquid.liquid_sources += src
	cell.is_liquid_source = TRUE
	cell.production_rate = 1  // Amount of liquid produced per tick

/turf/liquid_source/Destroy()
	SSliquid.liquid_sources -= src
	return ..()

/turf/liquid_sink
	name = "Liquid sink"

/turf/liquid_sink/Initialize()
	. = ..()
	SSliquid.liquid_sinks += src
	cell.is_liquid_sink = TRUE
	cell.absorption_rate = 1  // Amount of liquid absorbed per tick

/turf/liquid_sink/Destroy()
	SSliquid.liquid_sinks -= src
	return ..()

/datum/controller/subsystem/processing/liquid/proc/update_cell_image(turf/T)
	var/datum/liquid/mostfluid = T.get_highest_fluid_by_volume()

	if(mostfluid)
		T.liquid_overlay.color = mostfluid.color

	var/fluid_level = get_fluid_level(T)

	if(isopenspace(T) && T.cell?.flow_dir && fluid_level >= FLUID_FULL)
		T.liquid_overlay.icon_state = "rivermove"
		T.liquid_overlay.dir = T.cell.flow_dir

	switch(fluid_level)
		if(FLUID_EMPTY) T.liquid_overlay.alpha = 0
		if(FLUID_VERY_LOW) T.liquid_overlay.alpha = 80
		if(FLUID_LOW) T.liquid_overlay.alpha = 100
		if(FLUID_MEDIUM) T.liquid_overlay.alpha = 115
		if(FLUID_HIGH) T.liquid_overlay.alpha = 145
		if(FLUID_VERY_HIGH) T.liquid_overlay.alpha = 185
		if(FLUID_FULL)
			if(isopenspace(T) && GET_FLUID_LEVEL(T) > FLUID_EMPTY)
				T.liquid_overlay.alpha = 125
				T.liquid_overlay.color = T.liquid_overlay.color
				T.liquid_overlay.alpha = 80
			else
				T.liquid_overlay.alpha = 205
		if(FLUID_OVERFLOW)
			if(isopenspace(T) && GET_FLUID_LEVEL(T) > FLUID_EMPTY)
				T.liquid_overlay.alpha = 125
				T.liquid_overlay.color = T.liquid_overlay.color
				T.liquid_overlay.alpha = 80
			else
				T.liquid_overlay.alpha = 235

	if((T.cell.last_fluid_level < fluid_level) && (fluid_level >= FLUID_FULL) || (T.cell.last_fluid_level > fluid_level) && (fluid_level < FLUID_FULL))
		var/list/queue = list()
		var/list/pool = get_pool(T)
		var/pool_avg = get_pool_avg(pool)
		if(pool_avg > 70) queue[pool] = TRUE
		if(length(queue)) for(var/list/p as anything in queue) for(var/turf/in_pool as anything in p) in_pool.liquid_overlay.update_icon()


/datum/controller/subsystem/processing/liquid/proc/convert_fluid_to_reagent(datum/liquid/fluid, amount, atom/container, turf/T)
	return GLOB.liquid_manager.convert_fluid_to_reagent(fluid, amount, container, T)

/datum/controller/subsystem/processing/liquid/proc/convert_reagent_to_fluid(reagent_type, amount, atom/container, turf/T)
	return GLOB.liquid_manager.convert_reagent_to_fluid(reagent_type, amount, container, T)

//The testing spawner

/obj/item/liquid_spawner
	name = "Liquid Spawner"
	desc = "A magical device that spawns liquid."
	icon_state = "tome"
	var/fluid_amount = 10
	var/fluid = WATER

/obj/item/liquid_spawner/attack_self(mob/user)
	var/turf/T = get_turf(user)
	if(T)
		var/datum/liquid/t_fluid = T.get_fluid_datum(fluid)
		if(!t_fluid) CRASH ("Unable to find fluid data for [fluid] on [T] at [T.x], [T.y], [T.z]!")
		T += t_fluid * fluid_amount
		user.visible_message("[user] uses \the [src] to summon [fluid_amount] units of [t_fluid.name]. Total [t_fluid.name] volume: [T[t_fluid]].")

/obj/item/liquid_spawner/attack_right(mob/user)
	switch(fluid_amount)
		if(10) fluid_amount = 20
		if(20) fluid_amount = 30
		if(30) fluid_amount = 40
		if(40) fluid_amount = 50
		if(50) fluid_amount = 10
	to_chat(user, "<span class='notice'>The fluid transfer amount is now [fluid_amount].</span>")

/obj/item/liquid_spawner/ShiftRightClick(mob/user)
	if(fluid == WATER)
		fluid = FUEL
	else
		fluid = WATER
	to_chat(user, "<span class='notice'>The fluid type is now [fluid].</span>")

/obj/effect/liquid
	icon = 'icons/turf/newwater.dmi'
	icon_state = "bottom2"
	plane = GAME_PLANE
	layer = BELOW_MOB_LAYER
	mouse_opacity = 0
	var/list/trims
	var/list/current_trim_dirs

/obj/effect/water/trim/Initialize(direction)
	. = ..()
	dir = direction

/obj/effect/liquid/Initialize()
	. = ..()
	trims = list()
	current_trim_dirs = list()
	for(var/direction in GLOB.cardinals)
		trims["[direction]"] = new /obj/effect/water/trim(direction)
		current_trim_dirs["[direction]"] = FALSE

/obj/effect/liquid/update_icon()
	// Calculate which directions need trims based on current neighbor states
	var/list/needed_trim_dirs = list()
	for(var/direction in GLOB.cardinals)
		needed_trim_dirs["[direction]"] = FALSE

		var/turf/turf_to_check = get_step(src, direction)
		if(!turf_to_check?.cell) // Make sure this doesn't try updating icons before liquid datums get initialized
			continue

		// Skip certain turf types that don't need trims
		if(isopenspace(turf_to_check) || istype(turf_to_check, /turf/open/water) || (istype(turf_to_check, /turf/open/floor) && GET_FLUID_LEVEL(turf_to_check) >= FLUID_FULL))
			continue

		// Check if this direction needs a trim
		if(istype(turf_to_check, /turf/open) && GET_FLUID_LEVEL(turf_to_check) < FLUID_FULL && GET_FLUID_LEVEL(turf_to_check) >= FLUID_VERY_HIGH)
			needed_trim_dirs["[direction]"] = TRUE

	// Check if anything actually changed before modifying vis_contents
	var/changes_needed = FALSE
	for(var/direction in GLOB.cardinals)
		if(current_trim_dirs["[direction]"] != needed_trim_dirs["[direction]"])
			changes_needed = TRUE
			break

	// Only update vis_contents if changes are actually needed
	if(changes_needed)
		// Remove trims that are no longer needed
		for(var/direction in GLOB.cardinals)
			if(current_trim_dirs["[direction]"] && !needed_trim_dirs["[direction]"])
				vis_contents -= trims["[direction]"]
				current_trim_dirs["[direction]"] = FALSE

			// Add trims that are newly needed
			else if(!current_trim_dirs["[direction]"] && needed_trim_dirs["[direction]"])
				vis_contents += trims["[direction]"]
				current_trim_dirs["[direction]"] = TRUE


// Pressure flow: full tiles (>=60) push fluid to non-full neighbors
/datum/controller/subsystem/processing/liquid/proc/process_pressure_flow()
	for(var/turf/T as anything in cell_index)
		var/source_total = GET_TOTAL_FLUID(T)
		if(source_total < 60)
			continue // Not full enough for pressure

		// Check all cardinal directions for pressure outlets
		for(var/direction in list(NORTH, SOUTH, EAST, WEST, 0))
			var/turf/target
			if(direction == 0)
				// Check down for vertical pressure
				target = GetBelow(T)
			else
				target = get_step(T, direction)

			if(!target?.cell || target.blocks_flow())
				continue

			if(T.LinkBlocked(T, target))
				continue

			// Found a pressure outlet (not full)
			var/target_total = GET_TOTAL_FLUID(target)
			if(target_total < 60)
				var/total_pressure = source_total - 60
				var/max_push = MAX_FLUID_VOLUME - target_total

				var/pressure_amount = (min(total_pressure, max_push) * 3) / 10

				if(pressure_amount > 0)
					var/total_transferred = 0
					var/datum/liquid/first_fluid = null

					// Transfer each fluid type proportionally
					for(var/datum/liquid/fluid in T.cell.fluid_volume)
						var/fluid_amount = T.cell.fluid_volume[fluid]
						if(fluid_amount <= 0)
							continue

						if(!first_fluid)
							first_fluid = fluid

						var/fluid_transfer = (pressure_amount * fluid_amount) / source_total

						if(fluid_transfer > 0)
							T.cell.fluid_volume[fluid] -= fluid_transfer
							var/datum/liquid/target_fluid = GetLiquidInstance(fluid, target, FALSE)
							target.cell.fluid_volume[target_fluid] += fluid_transfer
							total_transferred += fluid_transfer

					// Handle remainder
					var/remainder = pressure_amount - total_transferred
					if(remainder > 0 && first_fluid)
						T.cell.fluid_volume[first_fluid] -= remainder
						var/datum/liquid/target_fluid = GetLiquidInstance(first_fluid, target, FALSE)
						target.cell.fluid_volume[target_fluid] += remainder

					T.cell.fluid_flags |= FLUID_MOVED
					target.cell.fluid_flags |= FLUID_MOVED
					cell_index[target] = TRUE

					if(pressure_amount >= 5)
						handle_flow_interaction(T, target, pressure_amount, TRUE, null)


//================================================================
// --- Pool Integration Functions ---
// These functions integrate the pool system with the
// main liquid subsystem processing cycle.
//================================================================

/**
 * Gets pool size for a turf.
 *
 * @param T The turf to get pool size for.
 * @return The size of the pool.
 */
/datum/controller/subsystem/processing/liquid/proc/get_safe_pool_size(turf/T)
	if(!T?.cell)
		return 0

	return GLOB.pool_manager.get_pool_size(T)


//================================================================
// --- Utility Functions ---
// Basic utility functions for the liquid subsystem.
//================================================================

/**
 * Optimizes the cell index by removing invalid entries.
 * Helps maintain performance when the cell index grows large.
 */
/datum/controller/subsystem/processing/liquid/proc/optimize_cell_index()
	var/list/invalid_entries = list()

	for(var/turf/T as anything in cell_index)
		if(!T?.cell || !can_process_fluid(T))
			invalid_entries += T

	if(length(invalid_entries) > 0)
		cell_index -= invalid_entries

/**
 * Gets comprehensive performance statistics for monitoring.
 * Provides detailed information about system performance and resource usage.
 *
 * @return An associative list of performance statistics.
 */
/datum/controller/subsystem/processing/liquid/proc/get_comprehensive_performance_stats()
	var/list/stats = list()

	// Basic processing statistics
	stats["phase"] = phase
	stats["cell_index_size"] = length(cell_index)
	stats["process_queue_size"] = length(process_queue)
	stats["reset_queue_size"] = length(reset_queue)
	stats["cells_in_processing"] = length(cells_in_processing)
	// cells_pending_sync stat removed - no longer used with direct volume sync

	// Performance optimization statistics
	stats["max_cells_per_tick"] = max_cells_per_tick

	// Pool manager statistics
	if(GLOB.pool_manager)
		var/list/pool_stats = GLOB.pool_manager.get_performance_statistics()
		for(var/stat_name in pool_stats)
			stats["pool_[stat_name]"] = pool_stats[stat_name]

	return stats
