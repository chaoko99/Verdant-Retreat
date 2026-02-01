/mob/living/simple_animal/hostile/retaliate

/mob/living/simple_animal/hostile/retaliate/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(M.used_intent.type == INTENT_HELP)
		if(ai_root?.blackboard[AIBLK_AGGRESSORS]?.len)
			if(tame)
				ai_root.blackboard[AIBLK_AGGRESSORS] = list()
				src.visible_message(span_notice("[src] calms down."))
				LoseTarget()

/mob/living/simple_animal/hostile/retaliate/proc/DismemberBody(mob/living/L)
	//Lets keep track of this to see if we start getting wounded while eating.
	testing("[src]_eating_[L]")
	//I dont know why but the do_after for health needs this to be defined like this.
	var/list/check_health = list("health" = src.health)

	if(L.stat != CONSCIOUS)
		src.visible_message(span_danger("[src] starts to rip apart [L]!"))
		if(attack_sound)
			playsound(src, pick(attack_sound), 100, TRUE, -1)
		//If their health is decreased at all during the 10 seconds the dismemberment will fail and they will lose target.
		if(do_after(user = src, delay = 10 SECONDS, target = L, extra_checks = CALLBACK(src, TYPE_PROC_REF(/mob, break_do_after_checks), check_health, FALSE)))
			//If its carbon remove a limb, if its some animal just gib it.
			if(iscarbon(L))
				var/mob/living/carbon/C = L
				var/obj/item/bodypart/limb
				var/static/list/limb_list = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD, BODY_ZONE_CHEST)
				var/list/candidates = list()
				for(var/zone in limb_list)
					limb = C.get_bodypart(zone)
					if(limb)
						candidates += limb

				limb = pick(candidates)
				if(limb)
					if(!limb.dismember())
						C.gib()
					return TRUE
			else
				L.gib()
				return TRUE
		LoseTarget()

/mob/living/simple_animal/hostile/retaliate/proc/Retaliate()
//	var/list/around = view(src, vision_range)
	SSai.WakeUp(src)
	var/list/around = get_nearby_entities(src, vision_range)

	if(!ai_root?.blackboard)
		return

	if(!ai_root.blackboard[AIBLK_AGGRESSORS])
		ai_root.blackboard[AIBLK_AGGRESSORS] = list()

	var/list/new_aggressors = list()
	for(var/mob/living/L as anything in around)
		if(faction_check_mob(L) && attack_same || !faction_check_mob(L))
			ai_root.blackboard[AIBLK_AGGRESSORS] |= L
			new_aggressors |= L

	for(var/mob/living/simple_animal/hostile/retaliate/H in around)
		if(faction_check_mob(H) && !attack_same && !H.attack_same)
			if(!H.ai_root?.blackboard)
				continue
			if(!H.ai_root.blackboard[AIBLK_AGGRESSORS])
				H.ai_root.blackboard[AIBLK_AGGRESSORS] = list()
			H.ai_root.blackboard[AIBLK_AGGRESSORS] |= new_aggressors
	return 0
	

/mob/living/simple_animal/hostile/retaliate/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(. > 0 && stat == CONSCIOUS)
		Retaliate()
