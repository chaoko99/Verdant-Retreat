/bt_action/has_faction_director
/bt_action/has_faction_director/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!blackboard)
		return NODE_FAILURE
	var/faction_director/director = blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE
	return NODE_SUCCESS

/bt_action/has_faction_task
/bt_action/has_faction_task/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!blackboard)
		return NODE_FAILURE
	var/faction_task/task = blackboard[AIBLK_FACTION_TASK]
	if(!task || QDELETED(task))
		return NODE_FAILURE
	return NODE_SUCCESS

/bt_action/request_faction_task
/bt_action/request_faction_task/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!user?.ai_root || !blackboard)
		return NODE_FAILURE
	if(user.ai_root.target)
		return NODE_FAILURE
	var/list/aggressors = blackboard[AIBLK_AGGRESSORS]
	if(aggressors && length(aggressors))
		return NODE_FAILURE

	var/faction_director/director = blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE

	var/faction_task/task = director.RequestTask(user)
	if(!task)
		return NODE_FAILURE

	blackboard[AIBLK_FACTION_TASK] = task
	blackboard[AIBLK_FACTION_TASK_TIMEOUT] = world.time + 60 SECONDS
	task.assigned_to = user

	return NODE_SUCCESS

/bt_action/execute_faction_task
/bt_action/execute_faction_task/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!blackboard)
		return NODE_FAILURE

	var/faction_task/task = blackboard[AIBLK_FACTION_TASK]
	if(!task || QDELETED(task))
		blackboard -= AIBLK_FACTION_TASK
		blackboard -= AIBLK_FACTION_TASK_TIMEOUT
		blackboard -= AIBLK_FACTION_TASK_DEST
		return NODE_FAILURE

	var/timeout = blackboard[AIBLK_FACTION_TASK_TIMEOUT]
	if(timeout && world.time > timeout)
		blackboard -= AIBLK_FACTION_TASK
		blackboard -= AIBLK_FACTION_TASK_TIMEOUT
		blackboard -= AIBLK_FACTION_TASK_DEST
		return NODE_FAILURE

	if(user.ai_root.target)
		return NODE_FAILURE
	var/list/aggressors = blackboard[AIBLK_AGGRESSORS]
	if(aggressors && length(aggressors))
		return NODE_FAILURE

	var/result = task.Execute(user)
	switch(result)
		if(NODE_SUCCESS)
			task.OnComplete(user)
			blackboard -= AIBLK_FACTION_TASK
			blackboard -= AIBLK_FACTION_TASK_TIMEOUT
			blackboard -= AIBLK_FACTION_TASK_DEST
			return NODE_SUCCESS
		if(NODE_FAILURE)
			blackboard -= AIBLK_FACTION_TASK
			blackboard -= AIBLK_FACTION_TASK_TIMEOUT
			blackboard -= AIBLK_FACTION_TASK_DEST
			return NODE_FAILURE

	return NODE_RUNNING

/bt_action/clear_faction_task
/bt_action/clear_faction_task/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!blackboard)
		return NODE_FAILURE
	blackboard -= AIBLK_FACTION_TASK
	blackboard -= AIBLK_FACTION_TASK_TIMEOUT
	blackboard -= AIBLK_FACTION_TASK_DEST
	return NODE_SUCCESS

/bt_action/contribute_faction_resources
/bt_action/contribute_faction_resources/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!blackboard)
		return NODE_FAILURE
	var/faction_director/director = blackboard[AIBLK_FACTION_DIRECTOR]
	if(!director || QDELETED(director))
		return NODE_FAILURE
	var/faction_task/gather/task = blackboard[AIBLK_FACTION_TASK]
	if(!istype(task))
		return NODE_FAILURE
	director.AddResource(task.resource_type, task.amount_to_gather)
	return NODE_SUCCESS

/datum/behavior_tree/node/action/has_faction_director
	my_action = /bt_action/has_faction_director

/datum/behavior_tree/node/action/has_faction_task
	my_action = /bt_action/has_faction_task

/datum/behavior_tree/node/action/request_faction_task
	my_action = /bt_action/request_faction_task

/datum/behavior_tree/node/action/execute_faction_task
	my_action = /bt_action/execute_faction_task

/datum/behavior_tree/node/action/clear_faction_task
	my_action = /bt_action/clear_faction_task

/datum/behavior_tree/node/action/contribute_faction_resources
	my_action = /bt_action/contribute_faction_resources

/datum/behavior_tree/node/sequence/execute_faction_task_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/has_faction_director,
		/datum/behavior_tree/node/action/has_faction_task,
		/datum/behavior_tree/node/action/execute_faction_task
	)

/datum/behavior_tree/node/sequence/request_faction_task_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/has_faction_director,
		/datum/behavior_tree/node/action/request_faction_task
	)

/datum/behavior_tree/node/selector/faction_ai_branch
	my_nodes = list(
		/datum/behavior_tree/node/sequence/execute_faction_task_sequence,
		/datum/behavior_tree/node/sequence/request_faction_task_sequence
	)
