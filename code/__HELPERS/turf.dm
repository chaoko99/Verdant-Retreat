/**
 * Get ranged target turf, but with direct targets as opposed to directions
 *
 * Starts at atom starting_atom and gets the exact angle between starting_atom and target
 * Moves from starting_atom with that angle, Range amount of times, until it stops, bound to map size
 * Arguments:
 * * starting_atom - Initial Firer / Position
 * * target - Target to aim towards
 * * range - Distance of returned target turf from starting_atom
 * * offset - Angle offset, 180 input would make the returned target turf be in the opposite direction
 */
/proc/get_ranged_target_turf_direct(atom/starting_atom, atom/target, range, offset)
	var/angle = ATAN2(target.x - starting_atom.x, target.y - starting_atom.y)
	if(offset)
		angle += offset
	var/turf/starting_turf = get_turf(starting_atom)
	for(var/i in 1 to range)
		var/turf/check = locate(starting_atom.x + cos(angle) * i, starting_atom.y + sin(angle) * i, starting_atom.z)
		if(!check)
			break
		starting_turf = check

	return starting_turf


/proc/TurfCircle(turf/center, radius=1)
	var/x=center.x, y=center.y, z=center.z
	// tolerance is roughly (radius+0.5)**2 - radius**2
	var/xo=radius, yo=0, tolerance=radius, d
	. = list()
	for(yo=d=0, yo<=radius, ++yo)
		. += block(x-xo,y-yo,z, x+xo,y-yo)
		if(yo) . += block(x-xo,y+yo,z, x+xo,y+yo)
		d = (yo++)*2+1; tolerance -= d
		while(tolerance < 0)
			d = (--xo)*2+1; tolerance += d
