// Global hash lookup table - built once on first use
GLOBAL_LIST_EMPTY(aiblk_hash_lookup)

/proc/reverse_lookup_hash(hash_value)
	if(!isnum(hash_value))
		return "[hash_value]"

	// Build lookup table on first use
	if(!length(GLOB.aiblk_hash_lookup))
		GLOB.aiblk_hash_lookup = list(
			"[AIBLK_LAST_TARGET]" = "AIBLK_LAST_TARGET", "[AIBLK_LAST_KNOWN_TARGET_LOC]" = "AIBLK_LAST_KNOWN_TARGET_LOC",
			"[AIBLK_PURSUE_TIME]" = "AIBLK_PURSUE_TIME", "[AIBLK_SEARCH_TIME]" = "AIBLK_SEARCH_TIME",
			"[AIBLK_SEARCH_START_TIME]" = "AIBLK_SEARCH_START_TIME", "[AIBLK_PURSUE_START_TIME]" = "AIBLK_PURSUE_START_TIME",
			"[AIBLK_FLEE_DIST]" = "AIBLK_FLEE_DIST", "[AIBLK_ACTION_TIMEOUT]" = "AIBLK_ACTION_TIMEOUT",
			"[AIBLK_TARGET_LOST_TIMER]" = "AIBLK_TARGET_LOST_TIMER", "[AIBLK_HIBERNATION_TIMER]" = "AIBLK_HIBERNATION_TIMER",
			"[AIBLK_FIND_TARGET_TIMER]" = "AIBLK_FIND_TARGET_TIMER", "[AIBLK_AGGRESSORS]" = "AIBLK_AGGRESSORS",
			"[AIBLK_AGRSR_RST_TMR]" = "AIBLK_AGRSR_RST_TMR", "[AIBLK_EXHAUSTED]" = "AIBLK_EXHAUSTED",
			"[AIBLK_KEEPAWAY_DIST]" = "AIBLK_KEEPAWAY_DIST", "[AIBLK_STAND_UP_TIMER]" = "AIBLK_STAND_UP_TIMER",
			"[AIBLK_UNDER_FIRE]" = "AIBLK_UNDER_FIRE", "[AIBLK_LAST_ATTACKER]" = "AIBLK_LAST_ATTACKER",
			"[AIBLK_IN_COVER]" = "AIBLK_IN_COVER", "[AIBLK_COVER_TIMER]" = "AIBLK_COVER_TIMER",
			"[AIBLK_MOVE_ACTIVE]" = "AIBLK_MOVE_ACTIVE", "[AIBLK_CHASE_TIMEOUT]" = "AIBLK_CHASE_TIMEOUT",
			"[AIBLK_ATTACKED_OBSTACLE]" = "AIBLK_ATTACKED_OBSTACLE", "[AIBLK_AI_COMMANDER]" = "AIBLK_AI_COMMANDER",
			"[AIBLK_BUMBLE_STATE]" = "AIBLK_BUMBLE_STATE", "[AIBLK_BUMBLE_NEXT_TICK]" = "AIBLK_BUMBLE_NEXT_TICK",
			"[AIBLK_COMBAT_STYLE]" = "AIBLK_COMBAT_STYLE", "[AIBLK_GRABBING]" = "AIBLK_GRABBING",
			"[AIBLK_BURST_COUNT]" = "AIBLK_BURST_COUNT", "[AIBLK_HIGH_VALUE_TARGET]" = "AIBLK_HIGH_VALUE_TARGET",
			"[AIBLK_STRAGGLER_TARGET]" = "AIBLK_STRAGGLER_TARGET", "[AIBLK_TIME_WAIT]" = "AIBLK_TIME_WAIT",
			"[AIBLK_AGGRO_LIST]" = "AIBLK_AGGRO_LIST", "[AIBLK_TIMER_DELAY]" = "AIBLK_TIMER_DELAY",
			"[AIBLK_BURROWING]" = "AIBLK_BURROWING", "[AIBLK_IS_ACTIVE]" = "AIBLK_IS_ACTIVE",
			"[AIBLK_CHARGE_RATE]" = "AIBLK_CHARGE_RATE", "[AIBLK_CURRENT_TARGET]" = "AIBLK_CURRENT_TARGET",
			"[AIBLK_SIGHT_RANGE]" = "AIBLK_SIGHT_RANGE", "[AIBLK_AGGRO_TICK]" = "AIBLK_AGGRO_TICK",
			"[AIBLK_HAS_ATTACKED]" = "AIBLK_HAS_ATTACKED", "[AIBLK_IDLE_SOUNDS]" = "AIBLK_IDLE_SOUNDS",
			"[AIBLK_IDLE_SOUND_TIMER]" = "AIBLK_IDLE_SOUND_TIMER", "[AIBLK_THREAT_SOUND]" = "AIBLK_THREAT_SOUND",
			"[AIBLK_THREAT_MESSAGE]" = "AIBLK_THREAT_MESSAGE", "[AIBLK_AGGRO_THRESHOLD]" = "AIBLK_AGGRO_THRESHOLD",
			"[AIBLK_CRITTER_PATH]" = "AIBLK_CRITTER_PATH", "[AIBLK_ATTACK_LIST]" = "AIBLK_ATTACK_LIST",
			"[AIBLK_IDEAL_RANGE]" = "AIBLK_IDEAL_RANGE", "[AIBLK_OBJECT_HIT]" = "AIBLK_OBJECT_HIT",
			"[AIBLK_BLOODTYPE]" = "AIBLK_BLOODTYPE", "[AIBLK_BLOODCOLOR]" = "AIBLK_BLOODCOLOR",
			"[AIBLK_HARVEST_LIST]" = "AIBLK_HARVEST_LIST", "[AIBLK_DAMAGE_OVERLAY]" = "AIBLK_DAMAGE_OVERLAY",
			"[AIBLK_OVERLAY_UPDATED]" = "AIBLK_OVERLAY_UPDATED", "[AIBLK_S_ACTION]" = "AIBLK_S_ACTION",
			"[AIBLK_AGGRESSION]" = "AIBLK_AGGRESSION", "[AIBLK_PATH_BLOCKED_COUNT]" = "AIBLK_PATH_BLOCKED_COUNT",
			"[AIBLK_SQUAD_ROLE]" = "AIBLK_SQUAD_ROLE", "[AIBLK_SQUAD_MATES]" = "AIBLK_SQUAD_MATES",
			"[AIBLK_SQUAD_SIZE]" = "AIBLK_SQUAD_SIZE", "[AIBLK_CHECK_TARGET]" = "AIBLK_CHECK_TARGET",
			"[AIBLK_CHOSEN_TARGET]" = "AIBLK_CHOSEN_TARGET", "[AIBLK_COMMAND_MODE]" = "AIBLK_COMMAND_MODE",
			"[AIBLK_DEFENDING_FROM_INTERRUPT]" = "AIBLK_DEFENDING_FROM_INTERRUPT", "[AIBLK_EATING_BODY]" = "AIBLK_EATING_BODY",
			"[AIBLK_FOLLOW_TARGET]" = "AIBLK_FOLLOW_TARGET", "[AIBLK_FOOD_TARGET]" = "AIBLK_FOOD_TARGET",
			"[AIBLK_FRIEND_REF]" = "AIBLK_FRIEND_REF", "[AIBLK_IGNORED_TARGETS]" = "AIBLK_IGNORED_TARGETS",
			"[AIBLK_IS_PINNING]" = "AIBLK_IS_PINNING", "[AIBLK_LAST_TARGET_SWITCH_TIME]" = "AIBLK_LAST_TARGET_SWITCH_TIME",
			"[AIBLK_MINION_FOLLOW_TARGET]" = "AIBLK_MINION_FOLLOW_TARGET", "[AIBLK_MINION_TRAVEL_DEST]" = "AIBLK_MINION_TRAVEL_DEST",
			"[AIBLK_PERFORM_EMOTE_ID]" = "AIBLK_PERFORM_EMOTE_ID", "[AIBLK_POSSIBLE_TARGETS]" = "AIBLK_POSSIBLE_TARGETS",
			"[AIBLK_REINFORCEMENTS_COOLDOWN]" = "AIBLK_REINFORCEMENTS_COOLDOWN", "[AIBLK_REINFORCEMENTS_SAY]" = "AIBLK_REINFORCEMENTS_SAY",
			"[AIBLK_TAMED]" = "AIBLK_TAMED", "[AIBLK_USE_TARGET]" = "AIBLK_USE_TARGET",
			"[AIBLK_VALID_TARGETS]" = "AIBLK_VALID_TARGETS", "[AIBLK_VIOLATION_INTERRUPTED]" = "AIBLK_VIOLATION_INTERRUPTED",
			"[AIBLK_DRAG_START_LOC]" = "AIBLK_DRAG_START_LOC", "[AIBLK_NEXT_HUNGER_CHECK]" = "AIBLK_NEXT_HUNGER_CHECK",
			"[AIBLK_PERFORM_SPEECH_TEXT]" = "AIBLK_PERFORM_SPEECH_TEXT", "[AIBLK_TARGETED_ACTION]" = "AIBLK_TARGETED_ACTION",
			"[AIBLK_DEADITE_MIGRATION_PATH]" = "AIBLK_DEADITE_MIGRATION_PATH", "[AIBLK_SQUAD_DATUM]" = "AIBLK_SQUAD_DATUM",
			"[AIBLK_SQUAD_PRIORITY_TARGET]" = "AIBLK_SQUAD_PRIORITY_TARGET", "[AIBLK_SQUAD_KNOWN_ENEMIES]" = "AIBLK_SQUAD_KNOWN_ENEMIES",
			"[AIBLK_SQUAD_TACTICAL_TARGET]" = "AIBLK_SQUAD_TACTICAL_TARGET", "[AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER]" = "AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER",
			"[AIBLK_SQUAD_HUNT_TARGET]" = "AIBLK_SQUAD_HUNT_TARGET", "[AIBLK_SQUAD_SHOULD_REGROUP]" = "AIBLK_SQUAD_SHOULD_REGROUP",
			"[AIBLK_SQUAD_PATROL_TARGET]" = "AIBLK_SQUAD_PATROL_TARGET", "[AIBLK_SQUAD_HUNT_LOCATION]" = "AIBLK_SQUAD_HUNT_LOCATION",
			"[AIBLK_MONSTER_BAIT]" = "AIBLK_MONSTER_BAIT", "[AIBLK_RESTRAIN_STATE]" = "AIBLK_RESTRAIN_STATE"
		)

	var/key_str = "[hash_value]"
	return GLOB.aiblk_hash_lookup[key_str] || key_str

/datum/behavior_tree_view
	var/mob/living/target
	var/datum/behavior_tree/node/parallel/root/root
	var/client/viewer
	var/obj/effect/outline_image
	var/image/outline_holder // These namings are intentional, you'll see
	var/list/selected_mobs = list()
	var/list/selection_images = list()
	var/selecting_mode = FALSE
	var/atom/drag_start

/datum/behavior_tree_view/New(client/C)
	viewer = C
	selected_mobs = list()
	selection_images = list()

/datum/behavior_tree_view/proc/set_target(mob/living/M)
	// Remove outline from old target
	if(outline_holder && viewer)
		viewer.images -= outline_holder
		qdel(outline_holder)
		outline_holder = null
	if(outline_image && viewer)
		qdel(outline_image)
		outline_image = null

	target = M
	if(istype(target))
		root = target.ai_root
		// Add outline to new target (client-only image, watch this crazy shit)
		outline_holder = image(icon = 'icons/mob/roguehud64.dmi', loc = target, icon_state = "blank")
		outline_holder.override = TRUE
		if(!outline_image)
			outline_image = new
		outline_image.appearance = target.appearance
		outline_image.vis_flags |= VIS_INHERIT_DIR
		outline_image.filters = filter(type = "outline", size = 2, color = "#00ffff")
		outline_holder.vis_contents += outline_image
		viewer.images += outline_holder
	else
		root = null

/datum/behavior_tree_view/ui_state(mob/user)
	if(!GLOB.admin_states["[R_DEBUG]"])
		GLOB.admin_states["[R_DEBUG]"] = new /datum/ui_state/admin_state(R_DEBUG)
	return GLOB.admin_states["[R_DEBUG]"]

/datum/behavior_tree_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BehaviorTreeDebug")
		ui.open()

/datum/behavior_tree_view/ui_data(mob/user)
	var/list/data = list()

	// Always provide selection and spawn data
	data["selected_count"] = length(selected_mobs)
	var/list/selected_list = list()
	for(var/mob/living/M in selected_mobs)
		selected_list += M.name
	data["selected_mobs"] = selected_list
	data["spawn_categories"] = get_spawn_categories()
	data["unit_tests"] = get_unit_tests()

	// Check if we have a target with AI
	if(!target || !root)
		data["has_ai"] = FALSE
		data["selecting"] = FALSE
		data["mob_name"] = ""
		data["blackboard"] = list()
		data["tree"] = null
		data["ai_state"] = null
		return data

	data["has_ai"] = TRUE
	data["selecting"] = FALSE
	data["mob_name"] = target.name
	data["blackboard"] = list()

	// Add AI state diagnostics
	var/list/ai_state = list()
	ai_state["has_target"] = root.target ? TRUE : FALSE
	ai_state["target_name"] = root.target ? "[root.target]" : "none"
	ai_state["target_stat"] = root.target && isliving(root.target) ? "[root.target:stat]" : "N/A"
	ai_state["has_move_destination"] = root.move_destination ? TRUE : FALSE
	ai_state["move_destination"] = root.move_destination ? "[root.move_destination]" : "none"
	ai_state["destination_same_as_target"] = (root.move_destination == root.target) ? TRUE : FALSE
	ai_state["path_length"] = length(root.path)
	ai_state["has_running_node"] = root.running_node ? TRUE : FALSE
	ai_state["running_node_type"] = root.running_node ? "[root.running_node.type]" : "none"
	ai_state["active_node_text"] = root.active_node_text ? "[root.active_node_text]" : "none"
	ai_state["next_think_tick"] = root.next_think_tick
	ai_state["next_move_tick"] = root.next_move_tick
	ai_state["world_time"] = world.time
	ai_state["can_think"] = (world.time >= root.next_think_tick) ? TRUE : FALSE
	ai_state["can_move"] = (world.time >= root.next_move_tick) ? TRUE : FALSE
	if(root.target)
		ai_state["distance_to_target"] = get_dist(target, root.target)
		ai_state["adjacent_to_target"] = target.Adjacent(root.target) ? TRUE : FALSE
	data["ai_state"] = ai_state

	if(root.blackboard)
		for(var/key in root.blackboard)
			var/value = root.blackboard[key]
			// Convert integer hash keys to strings for JSON compatibility
			var/key_str = reverse_lookup_hash(key)
			data["blackboard"] += list(list("key" = key_str, "value" = "[value]"))

	data["tree"] = get_node_data(root)

	return data

/datum/behavior_tree_view/proc/get_spawn_categories()
	var/list/categories = list()

	// Goblins
	var/list/goblins = list()
	goblins["Goblin"] = "/mob/living/carbon/human/species/goblin/npc"
	goblins["Goblin (Ambush)"] = "/mob/living/carbon/human/species/goblin/npc/ambush"
	goblins["Hell Goblin"] = "/mob/living/carbon/human/species/goblin/npc/hell"
	goblins["Cave Goblin"] = "/mob/living/carbon/human/species/goblin/npc/cave"
	goblins["Sea Goblin"] = "/mob/living/carbon/human/species/goblin/npc/sea"
	categories["Goblins"] = goblins

	// Humanoids
	var/list/humanoids = list()
	humanoids["Highwayman"] = "/mob/living/carbon/human/species/human/northern/highwayman"
	humanoids["Highwayman (Ambush)"] = "/mob/living/carbon/human/species/human/northern/highwayman/ambush"
	categories["Humanoids"] = humanoids

	// Squads
	var/list/squads = list()
	squads["Goblin Squad (Focus Fire)"] = "/obj/effect/mob_spawner/combat_test_goblin_squad"
	squads["Bandit Squad (Spread Out)"] = "/obj/effect/mob_spawner/combat_test_bandit_squad"
	categories["Combat Squads"] = squads

	return categories

/datum/behavior_tree_view/proc/get_unit_tests()
	var/list/tests = list()

	// Basic AI Tests
	tests += "Target Acquisition"
	tests += "Target Death Observer"
	tests += "Attack Cooldown Handling"
	tests += "Aggressor Management"
	tests += "Pathfinding"
	tests += "Combat Sequence"

	// Simple Animal Tests
	tests += "Direbear Ability Usage"
	tests += "Animal Eating Bodies"
	tests += "Chicken Egg Laying"
	tests += "Animal Scavenging"

	return tests

/datum/behavior_tree_view/proc/get_action_diagnostics(bt_action/action, mob/living/user)
	var/list/diag = list()

	if(!action || !user || !user.ai_root)
		return diag

	var/current_target = user.ai_root.target
	var/list/blackboard = user.ai_root.blackboard

	// has_valid_target
	if(istype(action, /bt_action/has_valid_target))
		diag["target_exists"] = current_target ? TRUE : FALSE
		diag["target_name"] = current_target ? "[current_target]" : "none"
		diag["target_stat"] = (current_target && isliving(current_target)) ? "[current_target:stat]" : "N/A"
		diag["target_alive"] = (current_target && isliving(current_target) && current_target:stat != DEAD) ? TRUE : FALSE

	// pick_best_target
	else if(istype(action, /bt_action/pick_best_target))
		var/list/candidates = blackboard ? blackboard[AIBLK_POSSIBLE_TARGETS] : null
		diag["candidates_exist"] = (candidates && length(candidates)) ? TRUE : FALSE
		diag["candidate_count"] = candidates ? length(candidates) : 0
		if(candidates && length(candidates))
			var/list/candidate_names = list()
			for(var/atom/A in candidates)
				candidate_names += "[A]"
			diag["candidate_list"] = candidate_names

	// target_in_range
	else if(istype(action, /bt_action/target_in_range))
		var/bt_action/target_in_range/tir = action
		diag["has_target"] = current_target ? TRUE : FALSE
		if(current_target)
			diag["distance"] = get_dist(user, current_target)
			diag["required_range"] = tir.range
			diag["in_range"] = (get_dist(user, current_target) <= tir.range) ? TRUE : FALSE

	// move_to_target
	else if(istype(action, /bt_action/move_to_target))
		diag["has_target"] = current_target ? TRUE : FALSE
		if(current_target)
			diag["distance"] = get_dist(user, current_target)
			diag["adjacent"] = user.Adjacent(current_target) ? TRUE : FALSE
			diag["has_path"] = length(user.ai_root.path) > 0 ? TRUE : FALSE
			diag["move_destination"] = user.ai_root.move_destination ? "[user.ai_root.move_destination]" : "none"

	// move_to_destination
	else if(istype(action, /bt_action/move_to_destination))
		var/atom/dest = user.ai_root.move_destination
		diag["has_destination"] = dest ? TRUE : FALSE
		diag["destination"] = dest ? "[dest]" : "none"
		diag["destination_is_target"] = (dest == current_target) ? TRUE : FALSE
		if(dest)
			diag["distance"] = get_dist(user, dest)
			diag["has_path"] = length(user.ai_root.path) > 0 ? TRUE : FALSE
			diag["path_length"] = length(user.ai_root.path)

	// check_think_valid
	else if(istype(action, /bt_action/check_think_valid))
		diag["user_stat"] = user.stat
		diag["is_dead"] = (user.stat == DEAD) ? TRUE : FALSE
		diag["world_time"] = world.time
		diag["next_think_tick"] = user.ai_root.next_think_tick
		diag["can_think"] = (world.time >= user.ai_root.next_think_tick) ? TRUE : FALSE
		diag["incapacitated"] = user.incapacitated(ignore_restraints = 1) ? TRUE : FALSE

	// check_move_valid
	else if(istype(action, /bt_action/check_move_valid))
		diag["world_time"] = world.time
		diag["next_move_tick"] = user.ai_root.next_move_tick
		diag["can_move"] = (world.time >= user.ai_root.next_move_tick) ? TRUE : FALSE

	// check_has_path
	else if(istype(action, /bt_action/check_has_path))
		diag["has_path"] = length(user.ai_root.path) > 0 ? TRUE : FALSE
		diag["path_length"] = length(user.ai_root.path)

	// ensure_blunt_weapon
	else if(istype(action, /bt_action/ensure_blunt_weapon))
		var/obj/item/left = user.get_active_held_item()
		var/obj/item/right = user.get_inactive_held_item()
		diag["left_hand"] = left ? "[left]" : "empty"
		diag["right_hand"] = right ? "[right]" : "empty"
		diag["both_hands_full"] = (left && right) ? TRUE : FALSE
		diag["has_free_hand"] = (!left || !right) ? TRUE : FALSE

	// grapple_target
	else if(istype(action, /bt_action/grapple_target))
		var/obj/item/grabbing/G = user.get_active_held_item()
		current_target = user.ai_root.target
		var/mob/living/bait = user.ai_root.blackboard ? user.ai_root.blackboard[AIBLK_MONSTER_BAIT] : null
		var/mob/living/victim = current_target ? current_target : bait
		diag["has_grab_object"] = istype(G) ? TRUE : FALSE
		diag["grab_object"] = G ? "[G]" : "none"
		diag["grabbed_target"] = (istype(G) && G.grabbed == victim) ? TRUE : FALSE
		diag["victim"] = victim ? "[victim]" : "none"
		diag["can_attack"] = (world.time >= user.ai_root.next_attack_tick) ? TRUE : FALSE

	// upgrade_grapple
	else if(istype(action, /bt_action/upgrade_grapple))
		var/obj/item/grabbing/G = user.get_active_held_item()
		diag["has_grab"] = istype(G) ? TRUE : FALSE
		diag["grab_state"] = istype(G) ? G.grab_state : "N/A"
		diag["is_aggressive"] = (istype(G) && G.grab_state >= GRAB_AGGRESSIVE) ? TRUE : FALSE

	// carbon_check_monster_bait
	else if(istype(action, /bt_action/carbon_check_monster_bait))
		current_target = user.ai_root.target
		diag["has_target"] = current_target ? TRUE : FALSE
		diag["target_name"] = current_target ? "[current_target]" : "none"
		if(ishuman(current_target))
			var/mob/living/carbon/human/H = current_target
			diag["has_monsterbait_trait"] = (H && HAS_TRAIT(H, TRAIT_MONSTERBAIT)) ? TRUE : FALSE

	// Generic info for all actions
	diag["action_type"] = "[action.type]"

	return diag

/datum/behavior_tree_view/proc/get_node_data(datum/behavior_tree/node/N)
	if(!N)
		return null

	var/list/node_data = list()
	node_data["type"] = "[N.type]"
	node_data["state"] = N.node_state
	node_data["children"] = list()
	node_data["diagnostics"] = list()

	// Default dynamic name
	var/txt = "[N.type]"
	var/last_slash = findlasttext(txt, "/")
	if(last_slash)
		txt = copytext(txt, last_slash + 1)
	node_data["name"] = txt

	if(istype(N, /datum/behavior_tree/node/action))
		var/datum/behavior_tree/node/action/A = N
		if(A.my_action)
			node_data["name"] = "[A.my_action.type]"
			// Clean up name for display
			var/last_slash_act = findlasttext(node_data["name"], "/")
			if(last_slash_act)
				node_data["name"] = copytext(node_data["name"], last_slash_act + 1)

			// Add action-specific diagnostics
			node_data["diagnostics"] = get_action_diagnostics(A.my_action, target)

	else if(istype(N, /datum/behavior_tree/node/selector))
		var/datum/behavior_tree/node/selector/S = N
		if(S.my_nodes)
			for(var/datum/behavior_tree/node/child in S.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/sequence))
		var/datum/behavior_tree/node/sequence/S = N
		if(S.my_nodes)
			for(var/datum/behavior_tree/node/child in S.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/decorator))
		var/datum/behavior_tree/node/decorator/D = N
		if(D.child)
			var/child_data = get_node_data(D.child)
			if(child_data)
				node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/parallel))
		var/datum/behavior_tree/node/parallel/P = N
		if(P.my_nodes)
			for(var/datum/behavior_tree/node/child in P.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	return node_data

/datum/behavior_tree_view/ui_close(mob/user)
	. = ..()
	cleanup()

/datum/behavior_tree_view/proc/cleanup()
	if(outline_holder && viewer)
		viewer.images -= outline_holder
		qdel(outline_holder)
		outline_holder = null
	if(outline_image && viewer)
		viewer.images -= outline_image
		qdel(outline_image)
		outline_image = null
	clear_selections()
	target = null
	root = null
	if(viewer)
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		if(viewer.mob)
			viewer.mob.update_mouse_pointer()

/datum/behavior_tree_view/proc/clear_selections()
	if(viewer)
		for(var/image/I in selection_images)
			viewer.images -= I
			qdel(I)
	selection_images = list()
	selected_mobs = list()

/datum/behavior_tree_view/proc/add_to_selection(mob/living/M)
	if(M in selected_mobs)
		return
	selected_mobs += M
	var/image/sel_img = new /image
	sel_img.override = TRUE
	sel_img.appearance = M.appearance
	sel_img.loc = M
	sel_img.filters += filter(type = "outline", size = 2, color = "#ffff00")
	selection_images += sel_img
	if(viewer)
		viewer.images += sel_img

/datum/behavior_tree_view/proc/remove_from_selection(mob/living/M)
	var/index = selected_mobs.Find(M)
	if(!index)
		return
	selected_mobs -= M
	var/image/sel_img = selection_images[index]
	if(viewer)
		viewer.images -= sel_img
	qdel(sel_img)
	selection_images -= sel_img

/datum/behavior_tree_view/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_selecting")
			// Enable click intercept mode
			viewer.click_intercept = src
			viewer.mouse_pointer_icon = 'icons/effects/mousemice/human_looking.dmi'
			selecting_mode = TRUE
			. = TRUE

		if("clear_selection")
			clear_selections()
			. = TRUE

		if("spawn_mob")
			var/path_string = params["path"]
			var/mob_path = text2path(path_string)
			if(!ispath(mob_path))
				to_chat(viewer.mob, span_warning("Invalid mob path: [path_string]"))
				return TRUE

			var/turf/spawn_loc = get_turf(viewer.mob)
			if(ispath(mob_path, /obj/effect/mob_spawner))
				var/obj/effect/mob_spawner/spawner = new mob_path(spawn_loc)
				spawner.attack_hand(viewer.mob)
				to_chat(viewer.mob, span_notice("Spawned squad spawner"))
			else if(ispath(mob_path, /mob/living))
				var/mob/living/new_mob = new mob_path(spawn_loc)
				to_chat(viewer.mob, span_notice("Spawned [new_mob.name] at your location"))
			else
				to_chat(viewer.mob, span_warning("Path is not a mob or spawner: [mob_path]"))
			. = TRUE

		if("delete_selected")
			for(var/mob/living/M in selected_mobs)
				qdel(M)
			clear_selections()
			to_chat(viewer.mob, span_notice("Deleted selected mobs"))
			. = TRUE

		if("run_unit_test")
			var/test_name = params["test_name"]
			run_unit_test(test_name)
			. = TRUE

/datum/behavior_tree_view/proc/InterceptClickOn(user, params, atom/target_atom)
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		// Right click cancels selection mode
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		viewer.mob.update_mouse_pointer()
		selecting_mode = FALSE
		drag_start = null
		return TRUE

	if(istype(target_atom, /atom/movable/screen))
		return FALSE

	// Check if ctrl-click for multi-select
	var/is_ctrl = modifiers["ctrl"]

	// Check if clicked on a living mob
	var/mob/living/clicked_mob = null
	if(isliving(target_atom))
		clicked_mob = target_atom
	else
		// Check if there's a mob at that location
		var/turf/T = get_turf(target_atom)
		if(T)
			for(var/mob/living/M in T)
				clicked_mob = M
				break

	if(clicked_mob)
		if(is_ctrl)
			// Multi-select with ctrl
			if(clicked_mob in selected_mobs)
				remove_from_selection(clicked_mob)
			else
				add_to_selection(clicked_mob)
			SStgui.update_uis(src)
		else
			// Single select - debug this mob
			set_target(clicked_mob)
			SStgui.update_uis(src)
			to_chat(user, span_notice("Now debugging behavior tree for: [clicked_mob.name]"))

			// Disable click intercept after selection
			viewer.click_intercept = null
			viewer.mouse_pointer_icon = null
			viewer.mob.update_mouse_pointer()
			selecting_mode = FALSE
	else
		to_chat(user, span_warning("No mob found at that location."))

	return TRUE

// Handle drag start
/datum/behavior_tree_view/proc/InterceptMouseDown(user, params, atom/object)
	var/list/modifiers = params2list(params)
	if(modifiers["shift"])
		drag_start = get_turf(object)
		return TRUE
	return FALSE

// Handle drag end - select all mobs in rectangle
/datum/behavior_tree_view/proc/InterceptMouseUp(user, params, atom/object)
	if(!drag_start)
		return FALSE

	var/turf/drag_end = get_turf(object)
	if(!drag_end)
		drag_start = null
		return FALSE

	// Get rectangle bounds
	var/min_x = min(drag_start.x, drag_end.x)
	var/max_x = max(drag_start.x, drag_end.x)
	var/min_y = min(drag_start.y, drag_end.y)
	var/max_y = max(drag_start.y, drag_end.y)
	var/z = drag_start.z

	// Select all mobs in rectangle
	clear_selections()
	for(var/mob/living/M in GLOB.mob_list)
		var/turf/M_turf = get_turf(M)
		if(!M_turf || M_turf.z != z)
			continue
		if(M_turf.x >= min_x && M_turf.x <= max_x && M_turf.y >= min_y && M_turf.y <= max_y)
			add_to_selection(M)

	SStgui.update_uis(src)
	to_chat(user, span_notice("Selected [length(selected_mobs)] mobs"))

	drag_start = null
	return TRUE

// ==============================================================================
// UNIT TESTS
// ==============================================================================

/datum/behavior_tree_view/proc/run_unit_test(test_name)
	to_chat(viewer.mob, span_notice("Running test: [test_name]"))

	switch(test_name)
		// Basic AI Tests
		if("Target Acquisition")
			test_target_acquisition()
		if("Target Death Observer")
			test_target_death_observer()
		if("Attack Cooldown Handling")
			test_attack_cooldown()
		if("Aggressor Management")
			test_aggressor_management()
		if("Pathfinding")
			test_pathfinding()
		if("Combat Sequence")
			test_combat_sequence()

		// Simple Animal Tests
		if("Direbear Ability Usage")
			test_direbear_ability()
		if("Animal Eating Bodies")
			test_animal_eating()
		if("Chicken Egg Laying")
			test_chicken_eggs()
		if("Animal Scavenging")
			test_animal_scavenging()

/datum/behavior_tree_view/proc/test_target_acquisition()
	// Spawn a goblin and a dummy target
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)
	var/mob/living/carbon/human/species/human/northern/dummy = new(locate(spawn_loc.x + 3, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned goblin and dummy 3 tiles away"))

	// Wait for AI to initialize
	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		// Force a think cycle
		SSai.WakeUp(goblin)
		sleep(5)

		// Check if target was acquired
		if(goblin.ai_root.target == dummy)
			to_chat(viewer.mob, span_good("PASS: Goblin acquired target"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Goblin did not acquire target. Target: [goblin.ai_root.target]"))

		// Check aggressors list
		if(goblin.ai_root.blackboard[AIBLK_AGGRESSORS])
			var/list/aggressors = goblin.ai_root.blackboard[AIBLK_AGGRESSORS]
			if(dummy in aggressors)
				to_chat(viewer.mob, span_good("PASS: Target added to aggressors list"))
			else
				to_chat(viewer.mob, span_warning("FAIL: Target not in aggressors list"))
		else
			to_chat(viewer.mob, span_warning("FAIL: No aggressors list created"))

/datum/behavior_tree_view/proc/test_target_death_observer()
	// Spawn a goblin and a dummy
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)
	var/mob/living/carbon/human/species/human/northern/dummy = new(locate(spawn_loc.x + 3, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned goblin and dummy"))

	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		// Manually set target
		goblin.ai_root.target = dummy
		if(!goblin.ai_root.blackboard[AIBLK_AGGRESSORS])
			goblin.ai_root.blackboard[AIBLK_AGGRESSORS] = list()
		goblin.ai_root.blackboard[AIBLK_AGGRESSORS] |= dummy

		to_chat(viewer.mob, span_notice("Killing dummy..."))
		dummy.death()
		sleep(5)

		// Check if target was cleared
		if(!goblin.ai_root.target)
			to_chat(viewer.mob, span_good("PASS: Target cleared on death"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Target not cleared. Current target: [goblin.ai_root.target]"))

		// Check running node cleared
		if(!goblin.ai_root.running_node)
			to_chat(viewer.mob, span_good("PASS: Running node cleared"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Running node not cleared"))

/datum/behavior_tree_view/proc/test_attack_cooldown()
	// Test that actions return NODE_RUNNING during cooldown
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)
	var/mob/living/carbon/human/species/human/northern/dummy = new(locate(spawn_loc.x + 1, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned adjacent goblin and dummy"))

	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		// Set target and attack
		goblin.ai_root.target = dummy
		var/initial_health = dummy.health

		// Trigger attack
		SSai.WakeUp(goblin)
		sleep(10)

		if(dummy.health < initial_health)
			to_chat(viewer.mob, span_good("PASS: Goblin attacked target"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Goblin did not attack"))

		// Check that next_attack_tick was set
		if(goblin.ai_root.next_attack_tick > world.time)
			to_chat(viewer.mob, span_good("PASS: Attack cooldown set (next_attack_tick: [goblin.ai_root.next_attack_tick], world.time: [world.time])"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Attack cooldown not set properly"))

/datum/behavior_tree_view/proc/test_aggressor_management()
	// Test that aggressors are added when attacked
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)

	to_chat(viewer.mob, span_notice("Test Setup: Spawned goblin, attacking it"))

	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		// Attack the goblin
		goblin.add_aggressor(viewer.mob)

		sleep(2)

		if(goblin.ai_root.blackboard[AIBLK_AGGRESSORS])
			var/list/aggressors = goblin.ai_root.blackboard[AIBLK_AGGRESSORS]
			if(viewer.mob in aggressors)
				to_chat(viewer.mob, span_good("PASS: Attacker added to aggressors list"))
			else
				to_chat(viewer.mob, span_warning("FAIL: Attacker not in aggressors list"))
		else
			to_chat(viewer.mob, span_warning("FAIL: No aggressors list created"))

/datum/behavior_tree_view/proc/test_pathfinding()
	// Test that AI can path to a distant target
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)
	var/turf/target_turf = locate(spawn_loc.x + 10, spawn_loc.y, spawn_loc.z)

	to_chat(viewer.mob, span_notice("Test Setup: Spawned goblin, setting distant path"))

	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		var/result = goblin.set_ai_path_to(target_turf)

		if(result)
			to_chat(viewer.mob, span_good("PASS: Pathfinding succeeded"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Pathfinding failed"))

		if(goblin.ai_root.path && length(goblin.ai_root.path) > 0)
			to_chat(viewer.mob, span_good("PASS: Path created (length: [length(goblin.ai_root.path)])"))
		else
			to_chat(viewer.mob, span_warning("FAIL: No path created"))

		if(goblin.ai_root.move_destination == target_turf)
			to_chat(viewer.mob, span_good("PASS: Move destination set correctly"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Move destination incorrect"))

/datum/behavior_tree_view/proc/test_combat_sequence()
	// Test full combat sequence
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_loc)
	var/mob/living/carbon/human/species/human/northern/dummy = new(locate(spawn_loc.x + 1, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Running full combat sequence test"))

	spawn(10)
		if(!goblin.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Goblin has no AI root"))
			return

		var/initial_health = dummy.health

		// Wake up AI and let it run
		SSai.WakeUp(goblin)
		sleep(50) // Give it time to acquire target and attack

		// Check if target was acquired
		var/acquired_target = FALSE
		if(goblin.ai_root.target == dummy || goblin.ai_root.blackboard[AIBLK_AGGRESSORS] && (dummy in goblin.ai_root.blackboard[AIBLK_AGGRESSORS]))
			to_chat(viewer.mob, span_good("PASS: Target acquired during combat"))
			acquired_target = TRUE
		else
			to_chat(viewer.mob, span_warning("FAIL: Target not acquired"))

		// Check if damage was dealt
		if(dummy.health < initial_health)
			to_chat(viewer.mob, span_good("PASS: Combat damage dealt ([initial_health - dummy.health] damage)"))
		else if(acquired_target)
			to_chat(viewer.mob, span_warning("FAIL: No damage dealt despite target acquisition"))
		else
			to_chat(viewer.mob, span_warning("FAIL: No damage dealt"))

		to_chat(viewer.mob, span_notice("Combat sequence test complete"))

// ==============================================================================
// SIMPLE ANIMAL UNIT TESTS
// ==============================================================================

/datum/behavior_tree_view/proc/test_direbear_ability()
	// Test that direbear uses its bear swipe ability
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/simple_animal/hostile/retaliate/rogue/direbear/bear = new(spawn_loc)
	var/mob/living/carbon/human/species/human/northern/dummy = new(locate(spawn_loc.x + 1, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned direbear and adjacent dummy"))

	spawn(10)
		if(!bear.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Direbear has no AI root"))
			return

		// Check if ability exists in blackboard
		var/datum/action/cooldown/ability = bear.ai_root.blackboard[AIBLK_TARGETED_ACTION]
		if(!ability)
			to_chat(viewer.mob, span_warning("FAIL: Direbear has no targeted action in blackboard"))
			return
		else
			to_chat(viewer.mob, span_good("PASS: Direbear has targeted action ([ability.type])"))

		// Set target and let AI run
		bear.ai_root.target = dummy
		var/initial_health = dummy.health

		// Wake up AI
		SSai.WakeUp(bear)
		sleep(30)

		// Check if ability was used (dummy should take damage)
		if(dummy.health < initial_health)
			to_chat(viewer.mob, span_good("PASS: Direbear dealt damage ([initial_health - dummy.health] damage)"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Direbear did not deal damage"))

		to_chat(viewer.mob, span_notice("Direbear ability test complete"))

/datum/behavior_tree_view/proc/test_animal_eating()
	// Test that animals can find and eat food
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/simple_animal/hostile/retaliate/rogue/direbear/bear = new(spawn_loc)
	var/obj/item/reagent_containers/food/snacks/rogue/meat/steak/meat = new(locate(spawn_loc.x + 2, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned direbear and meat 2 tiles away"))

	spawn(10)
		if(!bear.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Bear has no AI root"))
			return

		// Clear any target so it can scavenge
		bear.ai_root.target = null
		if(bear.ai_root.blackboard[AIBLK_AGGRESSORS])
			bear.ai_root.blackboard[AIBLK_AGGRESSORS] = list()

		// Set hunger check to now
		bear.ai_root.blackboard[AIBLK_NEXT_HUNGER_CHECK] = world.time

		SSai.WakeUp(bear)
		sleep(50) // Give time to find and eat

		// Check if food was eaten
		if(QDELETED(meat))
			to_chat(viewer.mob, span_good("PASS: Bear found and ate the meat"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Bear did not eat the meat"))

		// Check if food target was set in blackboard
		var/had_food_target = bear.ai_root.blackboard[AIBLK_FOOD_TARGET]
		if(had_food_target || QDELETED(meat))
			to_chat(viewer.mob, span_good("PASS: Food targeting system worked"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Food was not targeted"))

		to_chat(viewer.mob, span_notice("Animal eating test complete"))

/datum/behavior_tree_view/proc/test_chicken_eggs()
	// Test that chicken lays eggs
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/simple_animal/hostile/retaliate/rogue/chicken/chicken = new(spawn_loc)
	new /obj/structure/fluff/nest(spawn_loc)

	to_chat(viewer.mob, span_notice("Test Setup: Spawned chicken on a nest"))

	spawn(10)
		if(!chicken.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Chicken has no AI root"))
			return

		// Set production high enough to lay
		chicken.production = 30

		// Clear any aggression
		chicken.ai_root.target = null
		if(chicken.ai_root.blackboard[AIBLK_AGGRESSORS])
			chicken.ai_root.blackboard[AIBLK_AGGRESSORS] = list()

		SSai.WakeUp(chicken)
		sleep(30)

		// Check if egg was laid
		var/obj/item/reagent_containers/food/snacks/egg/E = locate(/obj/item/reagent_containers/food/snacks/egg) in spawn_loc
		if(E)
			to_chat(viewer.mob, span_good("PASS: Chicken laid an egg"))
		else
			to_chat(viewer.mob, span_warning("FAIL: No egg found on nest"))

		// Check if production was reduced
		if(chicken.production < 30)
			to_chat(viewer.mob, span_good("PASS: Chicken production reduced after laying ([chicken.production])"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Production not reduced ([chicken.production])"))

		to_chat(viewer.mob, span_notice("Chicken egg laying test complete"))

/datum/behavior_tree_view/proc/test_animal_scavenging()
	// Test comprehensive scavenging behavior
	var/turf/spawn_loc = get_turf(viewer.mob)
	var/mob/living/simple_animal/hostile/retaliate/rogue/chicken/chicken = new(spawn_loc)

	// Spawn food chicken likes (berries)
	var/obj/item/reagent_containers/food/snacks/grown/berries/rogue/berries = new(locate(spawn_loc.x + 3, spawn_loc.y, spawn_loc.z))

	to_chat(viewer.mob, span_notice("Test Setup: Spawned chicken with berries 3 tiles away"))

	spawn(10)
		if(!chicken.ai_root)
			to_chat(viewer.mob, span_warning("FAIL: Chicken has no AI root"))
			return

		// Clear aggression
		chicken.ai_root.target = null
		if(chicken.ai_root.blackboard[AIBLK_AGGRESSORS])
			chicken.ai_root.blackboard[AIBLK_AGGRESSORS] = list()

		// Set hunger check to now
		chicken.ai_root.blackboard[AIBLK_NEXT_HUNGER_CHECK] = world.time

		var/initial_food_level = chicken.food
		SSai.WakeUp(chicken)
		sleep(50)

		// Check if berries were eaten
		if(QDELETED(berries))
			to_chat(viewer.mob, span_good("PASS: Chicken found and ate berries"))
		else
			to_chat(viewer.mob, span_warning("FAIL: Chicken did not eat berries"))

		// Check if food level increased
		if(chicken.food > initial_food_level)
			to_chat(viewer.mob, span_good("PASS: Chicken food level increased ([initial_food_level] -> [chicken.food])"))
		else if(QDELETED(berries))
			to_chat(viewer.mob, span_warning("FAIL: Food level did not increase despite eating"))

		to_chat(viewer.mob, span_notice("Animal scavenging test complete"))
