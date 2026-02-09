// ==============================================================================
// FACTION AI DIRECTOR SUBSYSTEM
// ==============================================================================
// Manages high-level faction AI: resource gathering, goal management, spawning
// Similar to L4D2 AI Director but for RTS-style faction management
// ==============================================================================

PROCESSING_SUBSYSTEM_DEF(faction_ai)
	name = "Faction AI"
	priority = FIRE_PRIORITY_IDLE_NPC
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	wait = 5 SECONDS // Process faction AI every 5 seconds (much slower than individual mob AI)

	var/list/factions = list() // List of all faction_director datums
	var/list/factions_by_id = list() // Associative list for quick lookup by faction ID

/datum/controller/subsystem/processing/faction_ai/Initialize()
	. = ..()
	NEW_SS_GLOBAL(SSfaction_ai)

/datum/controller/subsystem/processing/faction_ai/fire(resumed = FALSE)
	for(var/faction_director/F as anything in factions)
		if(F && !QDELETED(F))
			INVOKE_ASYNC(F, TYPE_PROC_REF(/faction_director, ProcessFaction))

// Register a new faction
/datum/controller/subsystem/processing/faction_ai/proc/RegisterFaction(faction_director/F)
	if(!F || QDELETED(F))
		return FALSE

	if(!(F in factions))
		factions += F
		if(F.faction_id)
			factions_by_id[F.faction_id] = F
		return TRUE
	return FALSE

// Unregister a faction
/datum/controller/subsystem/processing/faction_ai/proc/UnregisterFaction(faction_director/F)
	if(!F)
		return

	factions -= F
	if(F.faction_id && factions_by_id[F.faction_id] == F)
		factions_by_id -= F.faction_id

// Get faction by ID
/datum/controller/subsystem/processing/faction_ai/proc/GetFaction(faction_id)
	return factions_by_id[faction_id]

// ==============================================================================
// FACTION DIRECTOR DATUM
// ==============================================================================
// Manages a single faction's resources, goals, and AI behavior
// ==============================================================================

/faction_director
	var/faction_id = "default" // Unique identifier for this faction
	var/faction_name = "Unknown Faction"
	var/list/faction_tags = list() // e.g., list("orcs", "goblins")

	// Resource management
	var/list/resources = list() // Associative list: resource_type -> amount
	var/list/resource_generation_rate = list() // Resource generation per cycle

	// Point system (L4D2-style director)
	var/director_points = 0 // Accumulated points for spending on actions
	var/points_per_cycle = 10 // Base points gained per processing cycle
	var/max_director_points = 1000 // Cap on stored points

	// Goals and tasks
	var/list/available_goals = list() // List of faction_goal datums
	var/list/active_goals = list() // Currently active goals
	var/list/pending_tasks = list() // Tasks waiting to be assigned to mobs

	// Spawning
	var/list/spawn_points = list() // List of turfs or objects where units can spawn
	var/list/spawn_budget = list() // mob_type -> max_count
	var/list/current_units = list() // mob_type -> current_count

	// Territory control
	var/list/controlled_areas = list() // Areas or turfs under faction control
	var/atom/faction_home_base // Central location for this faction

/faction_director/New(id, name)
	if(id)
		faction_id = id
	if(name)
		faction_name = name

	// Initialize resource tracking
	InitializeResources()

	// Initialize available goals
	InitializeGoals()

	// Register with subsystem
	SSfaction_ai.RegisterFaction(src)

/faction_director/Destroy()
	SSfaction_ai.UnregisterFaction(src)

	// Clean up goals
	for(var/faction_goal/G as anything in available_goals)
		qdel(G)
	for(var/faction_goal/G as anything in active_goals)
		qdel(G)

	available_goals.Cut()
	active_goals.Cut()
	pending_tasks.Cut()

	return ..()

// Initialize default resources
/faction_director/proc/InitializeResources()
	resources = list(
		"wood" = 0,
		"stone" = 0,
		"food" = 0,
		"metal" = 0
	)

	resource_generation_rate = list(
		"wood" = 0,
		"stone" = 0,
		"food" = 0,
		"metal" = 0
	)

// Override this in subtypes to add faction-specific goals
/faction_director/proc/InitializeGoals()
	// Base goals available to all factions
	available_goals += new /faction_goal/gather_resources(src, "wood")
	available_goals += new /faction_goal/gather_resources(src, "stone")
	available_goals += new /faction_goal/gather_resources(src, "food")

// Main processing loop for faction AI
/faction_director/proc/ProcessFaction()
	// 1. Update resources
	UpdateResources()

	// 2. Accumulate director points
	AccumulatePoints()

	// 3. Evaluate and select goals
	EvaluateGoals()

	// 4. Process active goals
	ProcessActiveGoals()

	// 5. Consider spawning new units
	ConsiderSpawning()

	// 6. Update unit tracking
	UpdateUnitTracking()

// Update resource stockpiles
/faction_director/proc/UpdateResources()
	for(var/resource_type in resource_generation_rate)
		var/generation = resource_generation_rate[resource_type]
		if(generation > 0)
			AddResource(resource_type, generation)

// Accumulate director points
/faction_director/proc/AccumulatePoints()
	director_points = min(director_points + points_per_cycle, max_director_points)

// Evaluate goals and activate high-priority ones
/faction_director/proc/EvaluateGoals()
	if(!length(available_goals))
		return

	// Score all available goals
	var/list/scored_goals = list()
	for(var/faction_goal/G as anything in available_goals)
		if(G.CanActivate(src))
			var/score = G.CalculateScore(src)
			if(score > 0)
				scored_goals[G] = score

	if(!length(scored_goals))
		return

	// Sort by score (highest first)
	var/list/sorted_goals = sortTim(scored_goals, /proc/cmp_numeric_dsc, TRUE)

	// Activate top goals if we have enough points
	for(var/faction_goal/G as anything in sorted_goals)
		if(director_points >= G.activation_cost)
			ActivateGoal(G)
			SpendPoints(G.activation_cost)
			break // Only activate one goal per cycle

// Activate a goal
/faction_director/proc/ActivateGoal(faction_goal/G)
	if(!G || (G in active_goals))
		return FALSE

	active_goals += G
	G.OnActivate(src)
	return TRUE

// Deactivate a goal
/faction_director/proc/DeactivateGoal(faction_goal/G)
	if(!G || !(G in active_goals))
		return FALSE

	active_goals -= G
	G.OnDeactivate(src)
	return TRUE

// Process all active goals
/faction_director/proc/ProcessActiveGoals()
	for(var/faction_goal/G as anything in active_goals)
		G.Process(src)

		// Check if goal is complete
		if(G.IsComplete(src))
			G.OnComplete(src)
			DeactivateGoal(G)

// Consider spawning new units based on resources and director points
/faction_director/proc/ConsiderSpawning()
	// Override in subtypes for faction-specific spawning logic
	return

// Update tracking of current units
/faction_director/proc/UpdateUnitTracking()
	// Clear current counts
	for(var/mob_type in current_units)
		current_units[mob_type] = 0

	// Count all units with matching faction tags
	for(var/mob/living/M in GLOB.mob_living_list)
		if(QDELETED(M) || M.stat == DEAD)
			continue

		// Check if mob belongs to this faction
		if(IsFactionMember(M))
			var/mob_type = M.type
			if(mob_type in current_units)
				current_units[mob_type]++
			else
				current_units[mob_type] = 1

// Check if a mob belongs to this faction
/faction_director/proc/IsFactionMember(mob/living/M)
	if(!M)
		return FALSE

	for(var/tag in faction_tags)
		if(tag in M.faction)
			return TRUE

	return FALSE

// Get a faction task for a mob to execute
/faction_director/proc/RequestTask(mob/living/M)
	if(!length(pending_tasks))
		return null

	// Return first available task (can be made smarter later)
	var/faction_task/T = pending_tasks[1]
	pending_tasks -= T
	return T

// Add a task to the pending queue
/faction_director/proc/AddTask(faction_task/T)
	if(!T)
		return
	pending_tasks += T

// Resource management
/faction_director/proc/AddResource(resource_type, amount)
	if(!(resource_type in resources))
		resources[resource_type] = 0
	resources[resource_type] += amount

/faction_director/proc/SpendResource(resource_type, amount)
	if(!(resource_type in resources))
		return FALSE
	if(resources[resource_type] < amount)
		return FALSE

	resources[resource_type] -= amount
	return TRUE

/faction_director/proc/GetResource(resource_type)
	return resources[resource_type] || 0

// Director points management
/faction_director/proc/SpendPoints(amount)
	if(director_points < amount)
		return FALSE
	director_points -= amount
	return TRUE

// Spawn a unit at a spawn point
/faction_director/proc/SpawnUnit(mob_type, turf/spawn_location)
	if(!spawn_location)
		// Pick a random spawn point
		if(!length(spawn_points))
			return null
		spawn_location = pick(spawn_points)

	var/mob/living/M = new mob_type(spawn_location)

	// Set faction
	if(M && length(faction_tags))
		M.faction = faction_tags.Copy()

	return M

// ==============================================================================
// FACTION GOALS
// ==============================================================================
// Represent high-level objectives for a faction
// ==============================================================================

/faction_goal
	var/goal_name = "Unknown Goal"
	var/goal_description = "No description"
	var/activation_cost = 50 // Director points required to activate
	var/base_score = 100 // Base priority score
	var/active = FALSE

/faction_goal/New(faction_director/director, ...)
	..()

/faction_goal/Destroy()
	active = FALSE
	return ..()

// Check if this goal can be activated
/faction_goal/proc/CanActivate(faction_director/director)
	return !active

// Calculate priority score for this goal (higher = more important)
/faction_goal/proc/CalculateScore(faction_director/director)
	return base_score

// Called when goal is activated
/faction_goal/proc/OnActivate(faction_director/director)
	active = TRUE

// Called when goal is deactivated
/faction_goal/proc/OnDeactivate(faction_director/director)
	active = FALSE

// Called each processing cycle while active
/faction_goal/proc/Process(faction_director/director)
	return

// Check if goal is complete
/faction_goal/proc/IsComplete(faction_director/director)
	return FALSE

// Called when goal is completed
/faction_goal/proc/OnComplete(faction_director/director)
	return

// ==============================================================================
// CONCRETE GOAL IMPLEMENTATIONS
// ==============================================================================

// Goal: Gather resources
/faction_goal/gather_resources
	goal_name = "Gather Resources"
	activation_cost = 30
	base_score = 80

	var/resource_type = "wood"
	var/target_amount = 100
	var/tasks_created = 0
	var/max_tasks = 3

/faction_goal/gather_resources/New(faction_director/director, res_type)
	..()
	if(res_type)
		resource_type = res_type
	goal_name = "Gather [resource_type]"

/faction_goal/gather_resources/CalculateScore(faction_director/director)
	var/current = director.GetResource(resource_type)
	var/deficit = target_amount - current

	if(deficit <= 0)
		return 0 // We have enough

	// Higher deficit = higher priority
	return base_score + (deficit / 10)

/faction_goal/gather_resources/OnActivate(faction_director/director)
	. = ..()
	tasks_created = 0

/faction_goal/gather_resources/Process(faction_director/director)
	// Create gathering tasks
	if(tasks_created < max_tasks)
		var/faction_task/gather/T = new /faction_task/gather()
		T.resource_type = resource_type
		T.amount_to_gather = 10
		director.AddTask(T)
		tasks_created++

/faction_goal/gather_resources/IsComplete(faction_director/director)
	return director.GetResource(resource_type) >= target_amount

// Goal: Spawn new units
/faction_goal/spawn_unit
	goal_name = "Recruit Units"
	activation_cost = 100
	base_score = 60

	var/mob_type_to_spawn
	var/spawn_count = 1
	var/resource_cost_type = "food"
	var/resource_cost_amount = 50

/faction_goal/spawn_unit/CanActivate(faction_director/director)
	if(!..())
		return FALSE

	// Check if we have resources
	return director.GetResource(resource_cost_type) >= resource_cost_amount

/faction_goal/spawn_unit/CalculateScore(faction_director/director)
	// Score higher if we have few units
	var/current_units = 0
	for(var/count in director.current_units)
		current_units += director.current_units[count]

	if(current_units >= 20) // Don't spam too many units
		return 0

	return base_score + (20 - current_units) * 5

/faction_goal/spawn_unit/OnActivate(faction_director/director)
	. = ..()

	// Spend resources and spawn unit
	if(director.SpendResource(resource_cost_type, resource_cost_amount))
		for(var/i = 1 to spawn_count)
			director.SpawnUnit(mob_type_to_spawn)

/faction_goal/spawn_unit/IsComplete(faction_director/director)
	return TRUE // Complete immediately after spawning

// ==============================================================================
// FACTION TASKS
// ==============================================================================
// Individual tasks that can be assigned to mobs
// ==============================================================================

/faction_task
	var/task_name = "Unknown Task"
	var/task_description = "No description"
	var/task_priority = 50 // Higher = more important
	var/assigned_to // mob reference
	var/completed = FALSE

/faction_task/proc/CanExecute(mob/living/M)
	return TRUE

/faction_task/proc/Execute(mob/living/M)
	return FALSE

/faction_task/proc/OnComplete(mob/living/M)
	completed = TRUE

// Task: Gather a resource
/faction_task/gather
	task_name = "Gather Resources"
	var/resource_type = "wood"
	var/amount_to_gather = 10
	var/turf/gather_location

/faction_task/gather/Execute(mob/living/M)
	// This would integrate with behavior trees
	// For now, just a placeholder
	return FALSE
