// ==============================================================================
// PATHFINDING HELPERS
// ==============================================================================
// The A* itself runs in verdant_native (see code/controllers/subsystem/
// pathfinding.dm); these are the public entry points and the LOS helpers.

// Global public API proc. This is the one you call elsewhere.
/proc/A_Star(mob/living/mover, turf/start, turf/end) as /list
	return SSpathfinding.FindPath(mover, start, end)

/// Packs this mob's pathfinding-relevant state into the native profile float:
/// obstacle-smashing intent, provocation (locked doors become bashable),
/// strength bonus and held-weapon force for the bash-cost formula.
/mob/living/proc/vn_path_profile()
	var/prof = 0
	if(ai_root?.ai_flags & AI_FLAG_SMASH_OBSTACLES)
		prof |= VN_PATH_SMASH
	if(ai_root?.target || (istype(src, /mob/living/simple_animal/hostile) && src:target))
		prof |= VN_PATH_PROVOKED
	if(STASTR)
		prof |= clamp(STASTR * 2, 0, 255) << 4
	// get_active_held_item() returns 0 (not null) on mobs without hands
	var/obj/item/W = get_active_held_item()
	if(isitem(W) && W.force)
		prof |= clamp(W.force, 0, 1023) << 12
	return prof

/proc/CanReach(mob/living/mover, turf/start, turf/end, depth = INFINITY) // A simple helper function to check if a path exists between two turfs. By default, has no depth limit. If you want to limit it, pass in a number.
	if (!mover || !start || !end)
		return FALSE

	var/list/path = A_Star(mover, start, end)

	if(path && length(path))
		return TRUE

	return FALSE

// ==============================================================================
// LINE OF SIGHT CHECKING VIA BRESENHAM'S LINE ALGORITHM
// ==============================================================================

/proc/__blocked(x, y, z, checkforcover = FALSE)
	var/turf/T = locate(x, y, z)
	if(!T) return TRUE

	if((checkforcover || T.density) && T.opacity) return TRUE

	for(var/atom/A in T.contents)
		if((checkforcover || A.density) && A.opacity)
			return TRUE
	return FALSE

/proc/los_blocked(atom/M, atom/N, checkforcover = FALSE)
	if(!M || !N || M.z != N.z)
		return TRUE

	var/px = M.x, py = M.y
	var/dx = N.x - px,  dy = N.y - py
	var/dxabs = abs(dx), dyabs = abs(dy)
	var/sdx = SIGN(dx), sdy = SIGN(dy)
	var/xerr = dxabs >> 1, yerr = dyabs >> 1

	// skip the starting turf (M's own tile) then begin stepping
	if(dxabs >= dyabs)
		for(var/i = dxabs; i > 0; --i)
			yerr += dyabs
			if(yerr >= dxabs)  { yerr -= dxabs; py += sdy }
			px += sdx
			if(__blocked(px, py, M.z, checkforcover)) return TRUE
	else
		for(var/i = dyabs; i > 0; --i)
			xerr += dxabs
			if(xerr >= dyabs) { xerr -= dyabs; px += sdx }
			py += sdy
			if(__blocked(px, py, M.z, checkforcover)) return TRUE

	return FALSE
