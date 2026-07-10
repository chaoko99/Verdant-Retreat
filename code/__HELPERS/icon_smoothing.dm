//generic (by snowflake) tile smoothing code; smooth your icons with this!
/*
	Each tile is divided in 4 corners, each corner has an appearance associated to it; the tile is then overlayed by these 4 appearances
	To use this, just set your atom's 'smoothing_flags' var to 1. If your atom can be moved/unanchored, set its 'can_be_unanchored' var to 1.
	If you don't want your atom's icon to smooth with anything but atoms of the same type, set the list 'canSmoothWith' to null;
	Otherwise, put all the smoothing groups you want the atom icon to smooth with in 'canSmoothWith', including the group of the atom itself.
	Smoothing groups are just shared flags between objects. If one of the 'canSmoothWith' of A matches one of the `smoothing_groups` of B, then A will smooth with B.

	Each atom has its own icon file with all the possible corner states. See 'smooth_wall.dmi' for a template.

	DIAGONAL SMOOTHING INSTRUCTIONS
	To make your atom smooth diagonally you need all the proper icon states (see 'smooth_wall.dmi' for a template) and
	to add the 'SMOOTH_DIAGONAL' flag to the atom's smoothing_flags var (in addition to either SMOOTH_TRUE or SMOOTH_MORE).

	For turfs, what appears under the diagonal corners depends on the turf that was in the same position previously: if you make a wall on
	a plating floor, you will see plating under the diagonal wall corner, if it was space, you will see space.

	If you wish to map a diagonal wall corner with a fixed underlay, you must configure the turf's 'fixed_underlay' list var, like so:
		fixed_underlay = list("icon"='icon_file.dmi', "icon_state"="iconstatename")
	A non null 'fixed_underlay' list var will skip copying the previous turf appearance and always use the list. If the list is
	not set properly, the underlay will default to regular floor plating.

	To see an example of a diagonal wall, see '/turf/closed/wall/mineral/titanium' and its subtypes.
*/

//Redefinitions of the diagonal directions so they can be stored in one var without conflicts
#define N_NORTH		(1<<1)
#define N_SOUTH		(1<<2)
#define N_EAST		(1<<4)
#define N_WEST		(1<<8)
#define N_NORTHEAST	(1<<5)
#define N_NORTHWEST	(1<<9)
#define N_SOUTHEAST	(1<<6)
#define N_SOUTHWEST	(1<<10)

#define SMOOTH_FALSE	0				//not smooth
#define SMOOTH_TRUE		(1<<0)	//smooths with exact specified types or just itself
#define SMOOTH_MORE		(1<<1)	//smooths with all subtypes of specified types or just itself (this value can replace SMOOTH_TRUE)
#define SMOOTH_DIAGONAL	(1<<2)	//if atom should smooth diagonally, this should be present in 'smooth' var
#define SMOOTH_BORDER	(1<<3)	//atom will smooth with the borders of the map
#define SMOOTH_QUEUED	(1<<4)	//atom is currently queued to smooth.

#define NULLTURF_BORDER 123456789

#define DEFAULT_UNDERLAY_ICON 			'icons/turf/floors.dmi'
#define DEFAULT_UNDERLAY_ICON_STATE 	"plating"

/atom/var/smooth = SMOOTH_FALSE
/atom/var/smooth_diag = TRUE
/atom/var/top_left_corner
/atom/var/top_right_corner
/atom/var/bottom_left_corner
/atom/var/bottom_right_corner
/atom/var/list/canSmoothWith = null // TYPE PATHS I CAN SMOOTH WITH~~~~~ If this is null and atom is smooth, it smooths only with itself
/atom/movable/var/can_be_unanchored = FALSE
/turf/var/list/fixed_underlay = null

/proc/calculate_adjacencies(atom/A)
	if(!A.loc)
		return 0

	var/adjacencies = 0

	var/atom/movable/AM
	if(ismovableatom(A))
		AM = A
		if(AM.can_be_unanchored && !AM.anchored)
			return 0

	for(var/direction in GLOB.cardinals)
		AM = find_type_in_direction(A, direction)
		if(AM == NULLTURF_BORDER)
			if((A.smooth & SMOOTH_BORDER))
				adjacencies |= 1 << direction
		else if( (AM && !istype(AM)) || (istype(AM) && AM.anchored) )
			adjacencies |= 1 << direction

	if(A.smooth_diag)
		if(adjacencies & N_NORTH)
			if(adjacencies & N_WEST)
				AM = find_type_in_direction(A, NORTHWEST)
				if(AM == NULLTURF_BORDER)
					if((A.smooth & SMOOTH_BORDER))
						adjacencies |= N_NORTHWEST
				else if( (AM && !istype(AM)) || (istype(AM) && AM.anchored) )
					adjacencies |= N_NORTHWEST
			if(adjacencies & N_EAST)
				AM = find_type_in_direction(A, NORTHEAST)
				if(AM == NULLTURF_BORDER)
					if((A.smooth & SMOOTH_BORDER))
						adjacencies |= N_NORTHEAST
				else if( (AM && !istype(AM)) || (istype(AM) && AM.anchored) )
					adjacencies |= N_NORTHEAST

		if(adjacencies & N_SOUTH)
			if(adjacencies & N_WEST)
				AM = find_type_in_direction(A, SOUTHWEST)
				if(AM == NULLTURF_BORDER)
					if((A.smooth & SMOOTH_BORDER))
						adjacencies |= N_SOUTHWEST
				else if( (AM && !istype(AM)) || (istype(AM) && AM.anchored) )
					adjacencies |= N_SOUTHWEST
			if(adjacencies & N_EAST)
				AM = find_type_in_direction(A, SOUTHEAST)
				if(AM == NULLTURF_BORDER)
					if((A.smooth & SMOOTH_BORDER))
						adjacencies |= N_SOUTHEAST
				else if( (AM && !istype(AM)) || (istype(AM) && AM.anchored) )
					adjacencies |= N_SOUTHEAST

	return adjacencies

//do not use, use queue_smooth(atom)
/proc/smooth_icon(atom/A)
	if(!A || !A.smooth)
		return
	A.smooth &= ~SMOOTH_QUEUED
	if (!A.z)
		return
	if(QDELETED(A))
		return
	if(A.smooth & (SMOOTH_TRUE | SMOOTH_MORE))
		var/adjacencies = calculate_adjacencies(A)

		if(A.smooth & SMOOTH_DIAGONAL)
			A.diagonal_smooth(adjacencies)
		else
			A.cardinal_smooth(adjacencies)

/atom/proc/diagonal_smooth(adjacencies)
	switch(adjacencies)
		if(N_NORTH|N_WEST)
			replace_smooth_overlays("d-se","d-se-0")
		if(N_NORTH|N_EAST)
			replace_smooth_overlays("d-sw","d-sw-0")
		if(N_SOUTH|N_WEST)
			replace_smooth_overlays("d-ne","d-ne-0")
		if(N_SOUTH|N_EAST)
			replace_smooth_overlays("d-nw","d-nw-0")

		if(N_NORTH|N_WEST|N_NORTHWEST)
			replace_smooth_overlays("d-se","d-se-1")
		if(N_NORTH|N_EAST|N_NORTHEAST)
			replace_smooth_overlays("d-sw","d-sw-1")
		if(N_SOUTH|N_WEST|N_SOUTHWEST)
			replace_smooth_overlays("d-ne","d-ne-1")
		if(N_SOUTH|N_EAST|N_SOUTHEAST)
			replace_smooth_overlays("d-nw","d-nw-1")

		else
			corners_cardinal_smooth(adjacencies)
			return FALSE

	icon_state = ""
	return TRUE

/atom/proc/corners_cardinal_smooth(adjacencies)
	//NW CORNER
	var/nw = "1-i"
	if((adjacencies & NORTH_JUNCTION) && (adjacencies & WEST_JUNCTION))
		if(adjacencies & NORTHWEST_JUNCTION)
			nw = "1-f"
		else
			nw = "1-nw"
	else
		if(adjacencies & NORTH_JUNCTION)
			nw = "1-n"
		else if(adjacencies & WEST_JUNCTION)
			nw = "1-w"

	//NE CORNER
	var/ne = "2-i"
	if((adjacencies & NORTH_JUNCTION) && (adjacencies & EAST_JUNCTION))
		if(adjacencies & NORTHEAST_JUNCTION)
			ne = "2-f"
		else
			ne = "2-ne"
	else
		if(adjacencies & NORTH_JUNCTION)
			ne = "2-n"
		else if(adjacencies & EAST_JUNCTION)
			ne = "2-e"

	//SW CORNER
	var/sw = "3-i"
	if((adjacencies & SOUTH_JUNCTION) && (adjacencies & WEST_JUNCTION))
		if(adjacencies & SOUTHWEST_JUNCTION)
			sw = "3-f"
		else
			sw = "3-sw"
	else
		if(adjacencies & SOUTH_JUNCTION)
			sw = "3-s"
		else if(adjacencies & WEST_JUNCTION)
			sw = "3-w"

	//SE CORNER
	var/se = "4-i"
	if((adjacencies & SOUTH_JUNCTION) && (adjacencies & EAST_JUNCTION))
		if(adjacencies & SOUTHEAST_JUNCTION)
			se = "4-f"
		else
			se = "4-se"
	else
		if(adjacencies & SOUTH_JUNCTION)
			se = "4-s"
		else if(adjacencies & EAST_JUNCTION)
			se = "4-e"

	var/list/new_overlays

	if(top_left_corner != nw)
		cut_overlay(top_left_corner)
		top_left_corner = nw
		LAZYADD(new_overlays, nw)

	if(top_right_corner != ne)
		cut_overlay(top_right_corner)
		top_right_corner = ne
		LAZYADD(new_overlays, ne)

	if(bottom_right_corner != sw)
		cut_overlay(bottom_right_corner)
		bottom_right_corner = sw
		LAZYADD(new_overlays, sw)

	if(bottom_left_corner != se)
		cut_overlay(bottom_left_corner)
		bottom_left_corner = se
		LAZYADD(new_overlays, se)

	if(new_overlays)
		add_overlay(new_overlays)

/turf/proc/edge_cardinal_smooth(adjacencies)
	var/list/New
	var/turf/used
	var/holder

	for(var/A in neighborlay_list)
		cut_overlay("[A]")
		neighborlay_list -= A

	if(adjacencies & NORTH_JUNCTION)
		used = get_step(src, NORTH)
		if(isturf(used) && (type != used.type))
			var/turf/T = used
			if(neighborlay_override)
				holder = "[neighborlay_override]-n"
				LAZYADD(New, holder)
				neighborlay_list += holder
			else if(T.neighborlay)
				holder = "[T.neighborlay]-n"
				LAZYADD(New, holder)
				neighborlay_list += holder
	if(adjacencies & SOUTH_JUNCTION)
		used = get_step(src, SOUTH)
		if(isturf(used) && (type != used.type))
			var/turf/T = used
			if(neighborlay_override)
				holder = "[neighborlay_override]-s"
				LAZYADD(New, holder)
				neighborlay_list += holder
			else if(T.neighborlay)
				holder = "[T.neighborlay]-s"
				LAZYADD(New, holder)
				neighborlay_list += holder
	if(adjacencies & WEST_JUNCTION)
		used = get_step(src, WEST)
		if(isturf(used) && (type != used.type))
			var/turf/T = used
			if(neighborlay_override)
				holder = "[neighborlay_override]-w"
				LAZYADD(New, holder)
				neighborlay_list += holder
			else if(T.neighborlay)
				holder = "[T.neighborlay]-w"
				LAZYADD(New, holder)
				neighborlay_list += holder
	if(adjacencies & EAST_JUNCTION)
		used = get_step(src, EAST)
		if(isturf(used) && (type != used.type))
			var/turf/T = used
			if(neighborlay_override)
				holder = "[neighborlay_override]-e"
				LAZYADD(New, holder)
				neighborlay_list += holder
			else if(T.neighborlay)
				holder = "[T.neighborlay]-e"
				LAZYADD(New, holder)
				neighborlay_list += holder

	if(New)
		add_overlay(New)
	return New

///Scans direction to find targets to smooth with.
/atom/proc/find_type_in_direction(direction)
	var/turf/target_turf = get_step(src, direction)
	if(!target_turf)
		return NULLTURF_BORDER

	if(isnull(smoothing_list)) //special case in which it will only smooth with itself
		if(isturf(src))
			return (type == target_turf.type) ? ADJ_FOUND : NO_ADJ_FOUND
		var/atom/matching_obj = locate(type) in target_turf
		return (matching_obj && matching_obj.type == type) ? ADJ_FOUND : NO_ADJ_FOUND

	if(!isnull(target_turf.smoothing_groups))
		for(var/target in smoothing_list)
			if(!(smoothing_list[target] & target_turf.smoothing_groups[target]))
				continue
			return ADJ_FOUND

	if(smoothing_flags & SMOOTH_OBJ)
		for(var/am in target_turf)
			var/atom/movable/thing = am
			if(!thing.anchored || isnull(thing.smoothing_groups))
				continue
			for(var/target in smoothing_list)
				if(!(smoothing_list[target] & thing.smoothing_groups[target]))
					continue
				return ADJ_FOUND

	return NO_ADJ_FOUND

/**
  * Basic smoothing proc. The atom checks for adjacent directions to smooth with and changes the icon_state based on that.
  *
  * Returns the previous smoothing_junction state so the previous state can be compared with the new one after the proc ends, and see the changes, if any.
  *
*/
/atom/proc/smooth(edge = FALSE)
	var/new_junction = NONE

	// cache for sanic speed
	var/smoothing_list = src.smoothing_list

	var/smooth_border = (smoothing_flags & SMOOTH_BORDER)
	var/smooth_obj = (smoothing_flags & SMOOTH_OBJ)
	var/smooth_edge = (smoothing_flags & SMOOTH_EDGE)

	#define SET_ADJ_IN_DIR(direction, direction_flag) \
		set_adj_in_dir: { \
			do { \
				var/turf/neighbor = get_step(src, direction); \
				if(!neighbor) { \
					if(smooth_border) { \
						new_junction |= direction_flag; \
					}; \
					break set_adj_in_dir; \
				}; \
				if(smooth_edge && type == neighbor.type) { \
					break set_adj_in_dir; \
				}; \
				if(smooth_obj) { \
					for(var/atom/movable/thing as anything in neighbor) { \
						if(!thing.anchored) { \
							continue; \
						}; \
						if(!smoothing_list) { \
							if(type == thing.type) { \
								new_junction |= direction_flag; \
								break set_adj_in_dir; \
							}; \
							continue; \
						}; \
						var/thing_smoothing_groups = thing.smoothing_groups; \
						if(!thing_smoothing_groups) { \
							continue; \
						}; \
						for(var/target in smoothing_list) { \
							if(smoothing_list[target] & thing_smoothing_groups[target]) { \
								new_junction |= direction_flag; \
								break set_adj_in_dir; \
							}; \
						}; \
					}; \
				}; \
				if(!smoothing_list) { \
					if(type == neighbor.type) { \
						new_junction |= direction_flag; \
					}; \
					break set_adj_in_dir; \
				}; \
				var/neighbor_smoothing_groups = neighbor.smoothing_groups; \
				if(neighbor_smoothing_groups) { \
					for(var/target as anything in smoothing_list) { \
						if(smoothing_list[target] & neighbor_smoothing_groups[target]) { \
							new_junction |= direction_flag; \
							break set_adj_in_dir; \
						}; \
					}; \
				}; \
				break set_adj_in_dir; \
			} while(FALSE) \
		}

	for(var/direction as anything in GLOB.cardinals) //Cardinal case first.
		SET_ADJ_IN_DIR(direction, direction)

	if(smooth_edge)
		if(!isturf(src))
			CRASH("[type] has SMOOTH_EDGE set but is not a turf!")
		var/turf/T = src
		T.set_neighborlays(new_junction)
		return

	if(smoothing_flags & SMOOTH_BITMASK_CARDINALS || !(new_junction & (NORTH|SOUTH)) || !(new_junction & (EAST|WEST)))
		set_smoothed_icon_state(new_junction)
		return

	if(new_junction & NORTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SET_ADJ_IN_DIR(NORTHWEST, NORTHWEST_JUNCTION)

		if(new_junction & EAST_JUNCTION)
			SET_ADJ_IN_DIR(NORTHEAST, NORTHEAST_JUNCTION)

	if(new_junction & SOUTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SET_ADJ_IN_DIR(SOUTHWEST, SOUTHWEST_JUNCTION)

		if(new_junction & EAST_JUNCTION)
			SET_ADJ_IN_DIR(SOUTHEAST, SOUTHEAST_JUNCTION)

	set_smoothed_icon_state(new_junction)

	#undef SET_ADJ_IN_DIR

///Changes the icon state based on the new junction bitmask.
/atom/proc/set_smoothed_icon_state(new_junction)
	icon_state = "[smoothing_icon]-[new_junction]"

/turf/proc/set_neighborlays(new_junction)
	remove_neighborlays()

	if(new_junction == NONE)
		return

	if(new_junction & NORTH)
		handle_edge_icon(NORTH)

	if(new_junction & SOUTH)
		handle_edge_icon(SOUTH)

	if(new_junction & EAST)
		handle_edge_icon(EAST)

	if(new_junction & WEST)
		handle_edge_icon(WEST)

/turf/proc/handle_edge_icon(dir)
	if(neighborlay_self)
		add_neighborlay(dir, neighborlay_self)
	if(neighborlay)
		// Reverse dir because we are offsetting the overlay onto the adjacency
		add_neighborlay(REVERSE_DIR(dir), neighborlay, TRUE)

/turf/proc/add_neighborlay(dir, edgeicon, offset = FALSE)
	var/add
	var/y = 0
	var/x = 0
	switch(dir)
		if(NORTH)
			add = "[edgeicon]-n"
			y = -32
		if(SOUTH)
			add = "[edgeicon]-s"
			y = 32
		if(EAST)
			add = "[edgeicon]-e"
			x = -32
		if(WEST)
			add = "[edgeicon]-w"
			x = 32

	if(!add)
		return

	var/image/overlay = image(icon, src, add, TURF_DECAL_LAYER, pixel_x = offset ? x : 0, pixel_y = offset ? y : 0 )

	LAZYADDASSOC(neighborlay_list, "[dir]", overlay)
	add_overlay(overlay)

/turf/proc/remove_neighborlays()
	for(var/key as anything in neighborlay_list)
		cut_overlay(neighborlay_list[key])
		qdel(neighborlay_list[key])
		neighborlay_list[key] = null
		LAZYREMOVE(neighborlay_list, key)

//Icon smoothing helpers
/proc/smooth_zlevel(zlevel, now = FALSE)
	var/list/away_turfs = block(locate(1, 1, zlevel), locate(world.maxx, world.maxy, zlevel))
	for(var/turf/T as anything in away_turfs)
		if(T.smoothing_flags & USES_SMOOTHING)
			if(now)
				T.smooth_icon()
			else
				QUEUE_SMOOTH(T)
		for(var/atom/A as anything in T)
			if(A.smoothing_flags & USES_SMOOTHING)
				if(now)
					A.smooth_icon()
				else
					QUEUE_SMOOTH(A)


/atom/proc/clear_smooth_overlays()
	cut_overlay(top_left_corner)
	top_left_corner = null
	cut_overlay(top_right_corner)
	top_right_corner = null
	cut_overlay(bottom_right_corner)
	bottom_right_corner = null
	cut_overlay(bottom_left_corner)
	bottom_left_corner = null

/atom/proc/replace_smooth_overlays(nw, ne, sw, se)
	clear_smooth_overlays()
	var/list/O = list()
	top_left_corner = nw
	O += nw
	top_right_corner = ne
	O += ne
	bottom_left_corner = sw
	O += sw
	bottom_right_corner = se
	O += se
	add_overlay(O)


/proc/reverse_ndir(ndir)
	switch(ndir)
		if(N_NORTH)
			return NORTH
		if(N_SOUTH)
			return SOUTH
		if(N_WEST)
			return WEST
		if(N_EAST)
			return EAST
		if(N_NORTHWEST)
			return NORTHWEST
		if(N_NORTHEAST)
			return NORTHEAST
		if(N_SOUTHEAST)
			return SOUTHEAST
		if(N_SOUTHWEST)
			return SOUTHWEST
		if(N_NORTH|N_WEST)
			return NORTHWEST
		if(N_NORTH|N_EAST)
			return NORTHEAST
		if(N_SOUTH|N_WEST)
			return SOUTHWEST
		if(N_SOUTH|N_EAST)
			return SOUTHEAST
		if(N_NORTH|N_WEST|N_NORTHWEST)
			return NORTHWEST
		if(N_NORTH|N_EAST|N_NORTHEAST)
			return NORTHEAST
		if(N_SOUTH|N_WEST|N_SOUTHWEST)
			return SOUTHWEST
		if(N_SOUTH|N_EAST|N_SOUTHEAST)
			return SOUTHEAST
		else
			return 0

//SSicon_smooth
/proc/queue_smooth_neighbors(atom/A)
	for(var/V in orange(1,A))
		var/atom/T = V
		if(T.smooth)
			queue_smooth(T)

//SSicon_smooth
/proc/queue_smooth(atom/A)
	if(!A.smooth || A.smooth & SMOOTH_QUEUED)
		return

	SSicon_smooth.smooth_queue += A
	SSicon_smooth.can_fire = 1
	A.smooth |= SMOOTH_QUEUED


//Example smooth wall
/turf/closed/wall/smooth
	name = "smooth wall"
	icon = 'icons/turf/smooth_wall.dmi'
	icon_state = "smooth"
	smooth = SMOOTH_TRUE|SMOOTH_DIAGONAL|SMOOTH_BORDER
	canSmoothWith = null

/proc/dir2neighbor(dir)
	switch(dir)
		if(NORTH) return N_NORTH
		if(SOUTH) return N_SOUTH
		if(EAST) return N_EAST
		if(WEST) return N_WEST
		if(NORTHEAST) return N_NORTHEAST
		if(NORTHWEST) return N_NORTHWEST
		if(SOUTHEAST) return N_SOUTHEAST
		if(SOUTHWEST) return N_SOUTHWEST

/proc/dir2abbr(dir)
	switch(dir)
		if(NORTH) return "n"
		if(SOUTH) return "s"
		if(EAST) return "e"
		if(WEST) return "w"
		if(NORTHEAST) return "ne"
		if(NORTHWEST) return "nw"
		if(SOUTHEAST) return "se"
		if(SOUTHWEST) return "sw"
