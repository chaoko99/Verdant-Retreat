/* PSEUDO:
#define BONUS_STATUS 1
#define BONUS_ITEM 2
#define BONUS_CIRCUMSTANCE 3

#define MALUS_STATUS 4
#define MALUS_ITEM 5
#define MALUS_CIRCUMSTANCE 6

var/myskill //ref to skill type this goes to. checked inside die rolling proc
var/mytype //contains what type of condition this is for the purposes of the status effect. Only pick the best/worst bonus/malus pair for a roll Probably assesss this during the 
condition being added to save time.

on mob
 var/list/roll_conditions = list[\
 SKILL = list[BONUS_STATUS=list(), BONUS_ITEM=list(), BONUS_CIRCUMSTANCE=list(), MALUS_STATUS=list(), MALUS_ITEM=list(), MALUS_CIRCUMSTANCE=list(), ],
and so forth

 
 ]]

during roll assess the following:
attribute bonus: 1 per 2 over 10, 1 per 4 over 16?
best modifiers
then roll dieIE: rolling against dc of 17
str=12

status array contains:
 SKILL = list[BONUS_STATUS=list(3,1), BONUS_ITEM=list(2), BONUS_CIRCUMSTANCE=list(3), MALUS_STATUS=list(1), MALUS_ITEM=list(1,2), MALUS_CIRCUMSTANCE=list(4,2), ],

so we get:
1d20+1(from str)+3+2+3-1-2-4 (from largest in each slot for status array)

roll:11, 11+1+3+2+3-1-2-4 = 13. fail.
*/
