/faction_director/goblin
	faction_id = "goblins_base"
	faction_name = "Goblin Tribe"
	faction_tags = list("orcs", "goblins_base")

	points_per_cycle = 15
	max_director_points = 500

/faction_director/goblin/InitializeResources()
	..()
	resources["scrap"] = 0
	resources["shinies"] = 0

/faction_director/goblin/InitializeGoals()
	..()
	available_goals += new /faction_goal/goblin_raid(src)
	available_goals += new /faction_goal/spawn_unit/spawn_goblin(src)
	available_goals += new /faction_goal/scavenge_scrap(src)

/faction_director/goblin/ConsiderSpawning()
	if(GetResource("food") >= 50 && director_points >= 100)
		if(prob(20))
			var/current_gob_count = 0
			for(var/count in current_units)
				current_gob_count += current_units[count]

			if(current_gob_count < 15)
				if(SpendResource("food", 50) && SpendPoints(100))
					SpawnUnit(/mob/living/carbon/human/species/goblin/npc)

/faction_director/goblin/sea
	faction_id = "sea_goblins"
	faction_name = "Sea Goblin Raiders"
	faction_tags = list("orcs", "goblins_sea")

/faction_director/goblin/sea/InitializeGoals()
	..()
	available_goals += new /faction_goal/goblin_coastal_raid(src)

/faction_director/goblin/sea/ConsiderSpawning()
	if(GetResource("food") >= 40 && director_points >= 80)
		if(prob(25))
			var/current_count = 0
			for(var/count in current_units)
				current_count += current_units[count]

			if(current_count < 20)
				if(SpendResource("food", 40) && SpendPoints(80))
					SpawnUnit(/mob/living/carbon/human/species/goblin/npc/sea)

/faction_director/goblin/cave
	faction_id = "cave_goblins"
	faction_name = "Cave Goblin Miners"
	faction_tags = list("orcs", "goblins_cave")

/faction_director/goblin/cave/InitializeGoals()
	..()
	available_goals += new /faction_goal/gather_resources(src, "stone")
	available_goals += new /faction_goal/gather_resources(src, "metal")
	available_goals += new /faction_goal/goblin_fortify(src)

/faction_director/goblin/cave/ConsiderSpawning()
	if(GetResource("stone") >= 100 && director_points >= 120)
		if(prob(15))
			var/current_count = 0
			for(var/count in current_units)
				current_count += current_units[count]

			if(current_count < 12)
				if(SpendResource("stone", 100) && SpendPoints(120))
					SpawnUnit(/mob/living/carbon/human/species/goblin/npc/cave)

/faction_goal/goblin_raid
	goal_name = "Raid Nearby Settlement"
	activation_cost = 200
	base_score = 120

	var/turf/raid_target
	var/list/task_refs = list()
	var/activation_time = 0

/faction_goal/goblin_raid/proc/find_raid_target()
	var/list/candidates = list()
	for(var/obj/effect/landmark/start/villagerlate/L in GLOB.start_landmarks_list)
		candidates += L
	if(length(candidates))
		return get_turf(pick(candidates))
	if(length(GLOB.player_list))
		var/mob/M = pick(GLOB.player_list)
		return get_turf(M)
	return null

/faction_goal/goblin_raid/CanActivate(faction_director/director)
	if(!..())
		return FALSE

	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	if(total_units < 8)
		return FALSE

	return find_raid_target() != null

/faction_goal/goblin_raid/CalculateScore(faction_director/director)
	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	if(total_units < 8)
		return 0

	return base_score + (total_units * 5)

/faction_goal/goblin_raid/OnActivate(faction_director/director)
	. = ..()
	raid_target = find_raid_target()
	task_refs = list()
	activation_time = world.time

/faction_goal/goblin_raid/Process(faction_director/director)
	if(!raid_target)
		return
	if(length(task_refs))
		return
	for(var/i in 1 to 5)
		var/faction_task/goblin_raid_task/T = new()
		T.raid_target = raid_target
		director.AddTask(T)
		task_refs += T

/faction_goal/goblin_raid/IsComplete(faction_director/director)
	if(!raid_target)
		return TRUE
	if(world.time >= activation_time + 5 MINUTES)
		return TRUE
	for(var/faction_task/goblin_raid_task/T as anything in task_refs)
		if(QDELETED(T) || !T.completed)
			return FALSE
	return TRUE

/faction_goal/goblin_coastal_raid
	parent_type = /faction_goal/goblin_raid
	goal_name = "Raid Coastal Area"
	activation_cost = 150
	base_score = 140

/faction_goal/goblin_coastal_raid/CalculateScore(faction_director/director)
	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	if(total_units < 6)
		return 0

	return base_score + (total_units * 7)

/faction_goal/spawn_unit/spawn_goblin
	goal_name = "Recruit Goblin"
	activation_cost = 50
	base_score = 100

	mob_type_to_spawn = /mob/living/carbon/human/species/goblin/npc
	spawn_count = 1
	resource_cost_type = "food"
	resource_cost_amount = 30

/faction_goal/spawn_unit/spawn_goblin/CalculateScore(faction_director/director)
	var/current_units = 0
	for(var/count in director.current_units)
		current_units += director.current_units[count]

	if(current_units >= 20)
		return 0

	var/food = director.GetResource("food")
	var/deficit = 20 - current_units

	return base_score + (deficit * 10) + (food / 10)

/faction_goal/scavenge_scrap
	goal_name = "Scavenge Scrap"
	activation_cost = 25
	base_score = 70

	var/list/active_tasks = list()

/faction_goal/scavenge_scrap/CalculateScore(faction_director/director)
	var/scrap = director.GetResource("scrap")

	if(scrap >= 100)
		return 0

	return base_score + (100 - scrap) / 5

/faction_goal/scavenge_scrap/OnActivate(faction_director/director)
	. = ..()
	active_tasks = list()

/faction_goal/scavenge_scrap/Process(faction_director/director)
	var/list/still_active = list()
	for(var/faction_task/scavenge/T as anything in active_tasks)
		if(!QDELETED(T) && !T.completed)
			still_active += T
	active_tasks = still_active

	if(length(active_tasks) >= 3)
		return

	var/faction_task/scavenge/T = new()
	T.scavenge_location = director.get_random_work_turf()
	director.AddTask(T)
	active_tasks += T

/faction_goal/scavenge_scrap/IsComplete(faction_director/director)
	return director.GetResource("scrap") >= 100

/faction_goal/goblin_fortify
	goal_name = "Fortify Cave"
	activation_cost = 100
	base_score = 90

/faction_goal/goblin_fortify/CalculateScore(faction_director/director)
	var/stone = director.GetResource("stone")
	var/wood = director.GetResource("wood")

	if(stone < 50 || wood < 50)
		return 0

	return base_score

/faction_goal/goblin_fortify/Process(faction_director/director)
	if(director.SpendResource("stone", 50) && director.SpendResource("wood", 50))
		director.fortification_level++

/faction_goal/goblin_fortify/IsComplete(faction_director/director)
	return TRUE

/faction_task/goblin_raid_task
	task_name = "Join Raid"
	task_priority = 80
	var/turf/raid_target

/faction_task/goblin_raid_task/Execute(mob/living/M)
	if(!M?.ai_root)
		return NODE_FAILURE
	if(!raid_target)
		return NODE_FAILURE

	M.ai_root.blackboard[AIBLK_FACTION_TASK_DEST] = raid_target
	if(get_dist(M, raid_target) <= 5)
		M.set_ai_path_to(null)
		M.ai_root.blackboard -= AIBLK_FACTION_TASK_DEST
		return NODE_SUCCESS
	if(M.set_ai_path_to(raid_target))
		return NODE_RUNNING
	return NODE_FAILURE

/proc/initialize_goblin_factions(list/portal_turfs)
	if(!length(portal_turfs))
		return

	var/faction_director/goblin/base_goblins = SSfaction_ai.GetFaction("goblins_base")
	if(!base_goblins)
		base_goblins = new()
	base_goblins.spawn_points |= portal_turfs
	if(!base_goblins.faction_home_base)
		base_goblins.faction_home_base = portal_turfs[1]

	var/faction_director/goblin/sea/sea_goblins = SSfaction_ai.GetFaction("sea_goblins")
	if(!sea_goblins)
		sea_goblins = new()
	sea_goblins.spawn_points |= portal_turfs
	if(!sea_goblins.faction_home_base)
		sea_goblins.faction_home_base = portal_turfs[1]

	var/faction_director/goblin/cave/cave_goblins = SSfaction_ai.GetFaction("cave_goblins")
	if(!cave_goblins)
		cave_goblins = new()
	cave_goblins.spawn_points |= portal_turfs
	if(!cave_goblins.faction_home_base)
		cave_goblins.faction_home_base = portal_turfs[1]

/mob/living/carbon/human/species/goblin/npc/proc/assign_faction_director(faction_id)
	if(!ai_root?.blackboard)
		return

	var/faction_director/director = SSfaction_ai.GetFaction(faction_id)
	if(!director)
		return

	ai_root.blackboard[AIBLK_FACTION_DIRECTOR] = director
