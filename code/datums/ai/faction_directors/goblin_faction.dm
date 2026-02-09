// ==============================================================================
// GOBLIN FACTION DIRECTOR
// ==============================================================================
// Example implementation of faction AI for goblin tribes
// Demonstrates resource gathering, spawning, and faction management
// ==============================================================================

/faction_director/goblin
	faction_id = "goblins_base"
	faction_name = "Goblin Tribe"
	faction_tags = list("orcs")

	// Goblin-specific settings
	points_per_cycle = 15 // Goblins accumulate points faster (more chaotic)
	max_director_points = 500

/faction_director/goblin/InitializeResources()
	..()
	// Goblins also track scrap and shiny objects
	resources["scrap"] = 0
	resources["shinies"] = 0

/faction_director/goblin/InitializeGoals()
	..()
	// Add goblin-specific goals
	available_goals += new /faction_goal/goblin_raid(src)
	available_goals += new /faction_goal/spawn_unit/spawn_goblin(src)
	available_goals += new /faction_goal/scavenge_scrap(src)

/faction_director/goblin/ConsiderSpawning()
	// Goblins can spawn randomly when they have enough resources
	if(GetResource("food") >= 50 && director_points >= 100)
		if(prob(20)) // 20% chance per cycle
			var/current_gob_count = 0
			for(var/count in current_units)
				current_gob_count += current_units[count]

			if(current_gob_count < 15) // Cap at 15 goblins
				if(SpendResource("food", 50) && SpendPoints(100))
					SpawnUnit(/mob/living/carbon/human/species/goblin/npc)

// ==============================================================================
// SEA GOBLIN FACTION
// ==============================================================================

/faction_director/goblin/sea
	faction_id = "sea_goblins"
	faction_name = "Sea Goblin Raiders"

/faction_director/goblin/sea/InitializeGoals()
	..()
	// Sea goblins prioritize raiding coastal areas
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

// ==============================================================================
// CAVE GOBLIN FACTION
// ==============================================================================

/faction_director/goblin/cave
	faction_id = "cave_goblins"
	faction_name = "Cave Goblin Miners"

/faction_director/goblin/cave/InitializeGoals()
	..()
	// Cave goblins focus on mining
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

// ==============================================================================
// GOBLIN FACTION GOALS
// ==============================================================================

// Goal: Conduct a raid
/faction_goal/goblin_raid
	goal_name = "Raid Nearby Settlement"
	activation_cost = 200
	base_score = 120

	var/raid_launched = FALSE

/faction_goal/goblin_raid/CanActivate(faction_director/director)
	if(!..())
		return FALSE

	// Need enough goblins to raid
	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	return total_units >= 8

/faction_goal/goblin_raid/CalculateScore(faction_director/director)
	// More goblins = higher raid desire
	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	if(total_units < 8)
		return 0

	// Score increases with goblin count
	return base_score + (total_units * 5)

/faction_goal/goblin_raid/OnActivate(faction_director/director)
	. = ..()
	raid_launched = FALSE

/faction_goal/goblin_raid/Process(faction_director/director)
	if(!raid_launched)
		// Create raid tasks for goblins
		var/tasks_created = 0
		for(var/i = 1 to 5)
			var/faction_task/goblin_raid_task/T = new()
			director.AddTask(T)
			tasks_created++

		raid_launched = TRUE

/faction_goal/goblin_raid/IsComplete(faction_director/director)
	return raid_launched // Complete immediately after launching

// Goal: Coastal raid (sea goblins)
/faction_goal/goblin_coastal_raid
	goal_name = "Raid Coastal Area"
	activation_cost = 150
	base_score = 140

/faction_goal/goblin_coastal_raid/CalculateScore(faction_director/director)
	// Sea goblins always want to raid if they have enough units
	var/total_units = 0
	for(var/count in director.current_units)
		total_units += director.current_units[count]

	if(total_units < 6)
		return 0

	return base_score + (total_units * 7)

// Goal: Spawn goblin units
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

	// Higher score when we have lots of food but few goblins
	var/food = director.GetResource("food")
	var/deficit = 20 - current_units

	return base_score + (deficit * 10) + (food / 10)

// Goal: Scavenge for scrap
/faction_goal/scavenge_scrap
	goal_name = "Scavenge Scrap"
	activation_cost = 25
	base_score = 70

/faction_goal/scavenge_scrap/CalculateScore(faction_director/director)
	var/scrap = director.GetResource("scrap")

	if(scrap >= 100)
		return 0 // Have enough scrap

	return base_score + (100 - scrap) / 5

/faction_goal/scavenge_scrap/Process(faction_director/director)
	// Create scavenging tasks
	var/faction_task/scavenge/T = new()
	director.AddTask(T)

/faction_goal/scavenge_scrap/IsComplete(faction_director/director)
	return director.GetResource("scrap") >= 100

// Goal: Fortify position (cave goblins)
/faction_goal/goblin_fortify
	goal_name = "Fortify Cave"
	activation_cost = 100
	base_score = 90

/faction_goal/goblin_fortify/CalculateScore(faction_director/director)
	var/stone = director.GetResource("stone")
	var/wood = director.GetResource("wood")

	if(stone < 50 || wood < 50)
		return 0 // Need resources first

	return base_score

/faction_goal/goblin_fortify/Process(faction_director/director)
	// Spend resources to fortify (placeholder)
	if(director.SpendResource("stone", 50) && director.SpendResource("wood", 50))
		// In a real implementation, this would create fortifications
		// For now, just log it
		return

/faction_goal/goblin_fortify/IsComplete(faction_director/director)
	return TRUE // Complete immediately

// ==============================================================================
// GOBLIN FACTION TASKS
// ==============================================================================

// Task: Participate in raid
/faction_task/goblin_raid_task
	task_name = "Join Raid"
	task_priority = 80

/faction_task/goblin_raid_task/Execute(mob/living/M)
	// This would integrate with behavior trees to make goblins move toward raid target
	// For now, just a placeholder that "completes" after some time
	return FALSE

// Task: Scavenge for items
/faction_task/scavenge
	task_name = "Scavenge"
	task_priority = 40

/faction_task/scavenge/Execute(mob/living/M)
	// Placeholder - would make goblins search for items
	return FALSE

// ==============================================================================
// HELPER PROCS FOR SETTING UP GOBLIN FACTIONS
// ==============================================================================

// Call this to initialize goblin faction directors at round start
/proc/initialize_goblin_factions()
	// Create sea goblin faction
	var/faction_director/goblin/sea/sea_goblins = new()
	sea_goblins.faction_home_base = null // Set to a specific location if needed

	// Create cave goblin faction
	var/faction_director/goblin/cave/cave_goblins = new()
	cave_goblins.faction_home_base = null // Set to a specific location if needed

	// You could create more factions here
	// The factions will automatically register with SSfaction_ai

// Example: Assign a faction director to a mob when it spawns
/mob/living/carbon/human/species/goblin/npc/proc/assign_faction_director(faction_id)
	if(!ai_root?.blackboard)
		return

	var/faction_director/director = SSfaction_ai.GetFaction(faction_id)
	if(!director)
		// Create a new director if it doesn't exist
		switch(faction_id)
			if("sea_goblins")
				director = new /faction_director/goblin/sea()
			if("cave_goblins")
				director = new /faction_director/goblin/cave()
			else
				director = new /faction_director/goblin()
				director.faction_id = faction_id

	ai_root.blackboard[AIBLK_FACTION_DIRECTOR] = director
