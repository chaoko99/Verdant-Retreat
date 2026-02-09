// ==============================================================================
// FACTION AI DIRECTOR - BEHAVIOR TREE INTEGRATION
// ==============================================================================
// Actions and conditions for integrating faction AI with mob behavior trees
// ==============================================================================

// ==============================================================================
// CONDITIONS
// ==============================================================================

// Check if mob has a faction director assigned
/datum/behavior_tree/node/decorator/has_faction_director
	name = "Has Faction Director"

/datum/behavior_tree/node/decorator/has_faction_director/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	var/faction_director/director = user.ai_root.blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE

	return Execute_Child(user, time_delta)

// Check if mob has a faction task assigned
/datum/behavior_tree/node/decorator/has_faction_task
	name = "Has Faction Task"

/datum/behavior_tree/node/decorator/has_faction_task/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	var/faction_task/task = user.ai_root.blackboard[AIBLK_FACTION_TASK]
	if(!task || QDELETED(task))
		return NODE_FAILURE

	return Execute_Child(user, time_delta)

// Check if mob is idle (no target, not in combat)
/datum/behavior_tree/node/decorator/is_idle
	name = "Is Idle"

/datum/behavior_tree/node/decorator/is_idle/Execute(mob/living/user, time_delta)
	if(!user?.ai_root)
		return NODE_FAILURE

	// Check if in combat
	if(user.ai_root.target)
		return NODE_FAILURE

	// Check if has aggressors
	if(user.ai_root.blackboard[AIBLK_AGGRESSORS] && length(user.ai_root.blackboard[AIBLK_AGGRESSORS]))
		return NODE_FAILURE

	return Execute_Child(user, time_delta)

// ==============================================================================
// ACTIONS
// ==============================================================================

// Request a task from the faction director
/datum/behavior_tree/node/action/request_faction_task
	name = "Request Faction Task"

/datum/behavior_tree/node/action/request_faction_task/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	var/faction_director/director = user.ai_root.blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE

	// Already has a task
	if(user.ai_root.blackboard[AIBLK_FACTION_TASK])
		return NODE_SUCCESS

	// Request a task from the director
	var/faction_task/task = director.RequestTask(user)
	if(!task)
		return NODE_FAILURE

	// Assign task to blackboard
	user.ai_root.blackboard[AIBLK_FACTION_TASK] = task
	user.ai_root.blackboard[AIBLK_FACTION_TASK_TIMEOUT] = world.time + 60 SECONDS
	task.assigned_to = user

	return NODE_SUCCESS

// Execute the assigned faction task
/datum/behavior_tree/node/action/execute_faction_task
	name = "Execute Faction Task"

/datum/behavior_tree/node/action/execute_faction_task/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	var/faction_task/task = user.ai_root.blackboard[AIBLK_FACTION_TASK]
	if(!task || QDELETED(task))
		// Clear invalid task
		user.ai_root.blackboard -= AIBLK_FACTION_TASK
		user.ai_root.blackboard -= AIBLK_FACTION_TASK_TIMEOUT
		return NODE_FAILURE

	// Check timeout
	var/timeout = user.ai_root.blackboard[AIBLK_FACTION_TASK_TIMEOUT]
	if(timeout && world.time > timeout)
		// Task timed out, clear it
		user.ai_root.blackboard -= AIBLK_FACTION_TASK
		user.ai_root.blackboard -= AIBLK_FACTION_TASK_TIMEOUT
		return NODE_FAILURE

	// Execute task
	var/result = task.Execute(user)
	if(result)
		// Task completed
		task.OnComplete(user)
		user.ai_root.blackboard -= AIBLK_FACTION_TASK
		user.ai_root.blackboard -= AIBLK_FACTION_TASK_TIMEOUT
		return NODE_SUCCESS

	return NODE_RUNNING

// Clear the current faction task
/datum/behavior_tree/node/action/clear_faction_task
	name = "Clear Faction Task"

/datum/behavior_tree/node/action/clear_faction_task/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	user.ai_root.blackboard -= AIBLK_FACTION_TASK
	user.ai_root.blackboard -= AIBLK_FACTION_TASK_TIMEOUT

	return NODE_SUCCESS

// Contribute resources to faction
/datum/behavior_tree/node/action/contribute_faction_resources
	name = "Contribute Faction Resources"
	var/resource_type = "wood"
	var/amount = 10

/datum/behavior_tree/node/action/contribute_faction_resources/Execute(mob/living/user, time_delta)
	if(!user?.ai_root?.blackboard)
		return NODE_FAILURE

	var/faction_director/director = user.ai_root.blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE

	// Add resources to faction (this is a placeholder - in reality you'd check if mob has resources)
	director.AddResource(resource_type, amount)

	return NODE_SUCCESS

// ==============================================================================
// EXAMPLE BEHAVIOR TREE WITH FACTION AI
// ==============================================================================
// This shows how to integrate faction AI into a mob's behavior tree
// Add this as a high-priority branch (before combat, but after critical actions)
// ==============================================================================

/datum/behavior_tree/node/selector/faction_ai_branch
	name = "Faction AI Branch"

/datum/behavior_tree/node/selector/faction_ai_branch/New()
	..()
	// Priority order:
	// 1. If has task, execute it
	// 2. If idle and has director, request a task
	// 3. Otherwise fail and let other branches handle behavior

	children = list(
		// Execute current task if we have one
		new /datum/behavior_tree/node/sequence/execute_faction_task_sequence(),

		// Request new task if idle
		new /datum/behavior_tree/node/sequence/request_faction_task_sequence()
	)

// Sequence for executing an existing faction task
/datum/behavior_tree/node/sequence/execute_faction_task_sequence
	name = "Execute Faction Task Sequence"

/datum/behavior_tree/node/sequence/execute_faction_task_sequence/New()
	..()
	children = list(
		new /datum/behavior_tree/node/decorator/has_faction_director(),
		new /datum/behavior_tree/node/decorator/has_faction_task(),
		new /datum/behavior_tree/node/action/execute_faction_task()
	)

// Sequence for requesting a new faction task
/datum/behavior_tree/node/sequence/request_faction_task_sequence
	name = "Request Faction Task Sequence"

/datum/behavior_tree/node/sequence/request_faction_task_sequence/New()
	..()
	children = list(
		new /datum/behavior_tree/node/decorator/has_faction_director(),
		new /datum/behavior_tree/node/decorator/is_idle(),
		new /datum/behavior_tree/node/action/request_faction_task()
	)

// ==============================================================================
// EXAMPLE: Goblin faction tree integration
// ==============================================================================
// You can modify the goblin tree to include faction AI like this:
// ==============================================================================

/*
Example modification to goblin_tree:

/datum/behavior_tree/node/selector/goblin_tree/New()
	..()
	children = list(
		new /datum/behavior_tree/node/selector/faction_ai_branch(), // ADD THIS FIRST
		new /datum/behavior_tree/node/decorator/goblin_update_squad_data(),
		new /datum/behavior_tree/node/selector/goblin_combat(),
		new /datum/behavior_tree/node/selector/goblin_idle()
	)

Then when spawning goblins, assign them a faction director:

/faction_director/goblin_faction
	faction_id = "sea_goblins"
	faction_name = "Sea Goblin Clan"
	faction_tags = list("orcs") // Match goblin faction tags

/faction_director/goblin_faction/InitializeGoals()
	..()
	// Add goblin-specific goals
	available_goals += new /faction_goal/spawn_unit/spawn_goblin(src)

/faction_goal/spawn_unit/spawn_goblin/New(faction_director/director)
	..()
	mob_type_to_spawn = /mob/living/carbon/human/species/goblin/npc/sea
	spawn_count = 1
	resource_cost_type = "food"
	resource_cost_amount = 25

Then in mob Initialize():
	var/faction_director/director = SSfaction_ai.GetFaction("sea_goblins")
	if(!director)
		director = new /faction_director/goblin_faction()
	ai_root.blackboard[AIBLK_FACTION_DIRECTOR] = director
*/
