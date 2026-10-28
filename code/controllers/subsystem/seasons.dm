#define SEASON_SPRING 1
#define SEASON_SUMMER 2
#define SEASON_FALL 3
#define SEASON_WINTER 4

//literally just a thing that holds a global var. That's all.
SUBSYSTEM_DEF(seasons)
	name = "seasons"
	flags = SS_NO_FIRE
	var/season = SEASON_SPRING
/datum/controller/subsystem/seasons/Initialize()
	season = pick(SEASON_SPRING,SEASON_SUMMER,SEASON_FALL, SEASON_WINTER)
