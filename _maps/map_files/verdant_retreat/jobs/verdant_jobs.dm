//Contains map specific jobs datums and landmarks.
/datum/job/roguetown/weaponsmith
	title = "Weaponsmith"
	flag = GUILDSMAN
	department_flag = YEOMEN
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	advclass_cat_rolls = list(CTAG_GUILDSMEN = 20)
	allowed_races = RACES_ALL_KINDS
	tutorial = "You are a member of the Scarlet Reach Guild of Crafts, a massive guild formed to represent the interests of all craftsmen in the township of Scarlet Reach.\
	As a Guildsman, you hail from the three most important constituent guilds: The Smith's Guild, the Artificer's Guild, and the Architect's Guild. The Guildsmaster has sway over you, but it is not absolute."
	outfit = /datum/outfit/job/guildsman
	selection_color = JCOLOR_YEOMAN
	display_order = JDO_GUILDSMAN
	give_bank_account = 15
	min_pq = 5
	max_pq = null
	round_contrib_points = 3
	advjob_examine = TRUE // So that everyone know which subjob they have picked
	social_rank = SOCIAL_RANK_YEOMAN

	job_subclasses = list(
		/datum/advclass/guildsman/artificer,
		/datum/advclass/guildsman/blacksmith,
		/datum/advclass/guildsman/architect
	)

/obj/effect/landmark/start/weaponsmith
	name = "Weaponsmith"
	icon_state = "arrow"


/obj/effect/landmark/start/armorsmith
	name = "Weaponsmith"
	icon_state = "arrow"

/obj/effect/landmark/start/metalsmith
	name = "Weaponsmith"
	icon_state = "arrow"
