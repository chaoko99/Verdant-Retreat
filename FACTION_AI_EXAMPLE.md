# Faction AI Director - Complete Example

This is a step-by-step example showing how to implement a simple resource-gathering faction AI.

## Scenario: Wood Gatherer Goblins

We want goblins to:
1. Automatically gather wood from trees
2. Store wood in a faction stockpile
3. Spend wood to spawn more goblins when they have enough
4. Only gather wood when idle (not in combat)

## Step 1: Create the Faction Director

```dm
// File: code/datums/ai/faction_directors/wood_gatherer_faction.dm

/faction_director/wood_gatherer
    faction_id = "wood_gatherers"
    faction_name = "Wood Gatherer Tribe"
    faction_tags = list("orcs") // Goblins use "orcs" faction tag

/faction_director/wood_gatherer/InitializeGoals()
    ..()
    // Add goals for this faction
    available_goals += new /faction_goal/gather_wood_goal(src)
    available_goals += new /faction_goal/spawn_wood_goblin(src)

/faction_director/wood_gatherer/ConsiderSpawning()
    // Auto-spawn when we have enough wood
    if(GetResource("wood") >= 100 && director_points >= 150)
        var/current_goblins = 0
        for(var/count in current_units)
            current_goblins += current_units[count]

        if(current_goblins < 10) // Cap at 10 goblins
            if(SpendResource("wood", 100) && SpendPoints(150))
                // Spawn at home base or random spawn point
                SpawnUnit(/mob/living/carbon/human/species/goblin/npc)
```

## Step 2: Create the Goals

```dm
// Goal: Keep wood stockpile high
/faction_goal/gather_wood_goal
    goal_name = "Gather Wood"
    activation_cost = 30 // Cheap to activate
    base_score = 100

/faction_goal/gather_wood_goal/CalculateScore(faction_director/director)
    var/current_wood = director.GetResource("wood")

    // If we have less than 50 wood, high priority
    if(current_wood < 50)
        return base_score + (50 - current_wood) * 2

    // If we have 50-100 wood, medium priority
    if(current_wood < 100)
        return base_score / 2

    // If we have 100+ wood, low priority
    return base_score / 4

/faction_goal/gather_wood_goal/Process(faction_director/director)
    // Create wood gathering tasks for idle goblins
    // Create up to 3 tasks per cycle
    for(var/i = 1 to 3)
        var/faction_task/gather_wood_task/T = new()
        director.AddTask(T)

/faction_goal/gather_wood_goal/IsComplete(faction_director/director)
    // Never "complete" - keep this goal active
    return FALSE

// Goal: Spawn new goblins
/faction_goal/spawn_wood_goblin
    goal_name = "Recruit Wood Gatherer"
    activation_cost = 100
    base_score = 80

/faction_goal/spawn_wood_goblin/CanActivate(faction_director/director)
    if(!..())
        return FALSE
    // Need at least 100 wood to spawn
    return director.GetResource("wood") >= 100

/faction_goal/spawn_wood_goblin/CalculateScore(faction_director/director)
    var/current_goblins = 0
    for(var/count in director.current_units)
        current_goblins += director.current_units[count]

    if(current_goblins >= 10)
        return 0 // Have enough

    var/wood = director.GetResource("wood")
    if(wood < 100)
        return 0 // Not enough resources

    // More wood = higher desire to spawn
    return base_score + (wood / 10)

/faction_goal/spawn_wood_goblin/OnActivate(faction_director/director)
    . = ..()
    // Spend wood and spawn goblin
    if(director.SpendResource("wood", 100))
        director.SpawnUnit(/mob/living/carbon/human/species/goblin/npc)

/faction_goal/spawn_wood_goblin/IsComplete(faction_director/director)
    return TRUE // Complete immediately
```

## Step 3: Create the Task

```dm
// Task: Gather wood from a tree
/faction_task/gather_wood_task
    task_name = "Gather Wood"
    task_priority = 60

    var/obj/structure/flora/tree/target_tree
    var/wood_gathered = 0
    var/wood_to_gather = 10

/faction_task/gather_wood_task/CanExecute(mob/living/M)
    // Only if not in combat
    if(M.ai_root?.target)
        return FALSE
    return TRUE

/faction_task/gather_wood_task/Execute(mob/living/M)
    // Find a tree if we don't have one
    if(!target_tree || QDELETED(target_tree))
        target_tree = find_nearest_tree(M)
        if(!target_tree)
            // No trees found, complete task
            return TRUE

    // Move to tree
    if(get_dist(M, target_tree) > 1)
        M.set_ai_path_to(target_tree)
        return FALSE // Still working

    // At tree, "chop" it
    // (This is simulated - in reality you'd have actual tree objects)
    wood_gathered += 2

    if(wood_gathered >= wood_to_gather)
        // Done gathering, add to faction
        var/faction_director/director = M.ai_root?.blackboard[AIBLK_FACTION_DIRECTOR]
        if(director)
            director.AddResource("wood", wood_gathered)

        return TRUE // Complete

    return FALSE // Keep gathering

/faction_task/gather_wood_task/proc/find_nearest_tree(mob/living/M)
    // Find nearest tree structure
    // (Placeholder - you'd implement this based on your tree objects)
    var/list/nearby_turfs = view(10, M)
    for(var/turf/T in nearby_turfs)
        for(var/obj/structure/flora/tree/tr in T)
            if(!tr.chopped) // Assuming trees have a chopped var
                return tr
    return null
```

## Step 4: Set Up Spawner/Initializer

```dm
// Spawn the faction director at round start
/datum/controller/subsystem/processing/faction_ai/Initialize()
    . = ..()

    // Create wood gatherer faction
    var/faction_director/wood_gatherer/WG = new()
    WG.faction_home_base = locate_wood_gatherer_spawn() // Your spawn location
    WG.spawn_points = list(WG.faction_home_base)

    // Start them with some initial resources
    WG.AddResource("wood", 20)
    WG.AddResource("food", 50)

// Helper to assign goblins to the faction when they spawn
/mob/living/carbon/human/species/goblin/npc/Initialize()
    . = ..()

    // Check if we should join wood gatherer faction
    if(should_join_wood_gatherers()) // Your logic
        assign_to_wood_gatherers()

/mob/living/carbon/human/species/goblin/npc/proc/assign_to_wood_gatherers()
    if(!ai_root?.blackboard)
        return

    var/faction_director/director = SSfaction_ai.GetFaction("wood_gatherers")
    if(!director)
        // Create faction if it doesn't exist
        director = new /faction_director/wood_gatherer()

    ai_root.blackboard[AIBLK_FACTION_DIRECTOR] = director
```

## Step 5: Integrate with Goblin Behavior Tree

```dm
// Modify goblin behavior tree to check faction tasks first
/datum/behavior_tree/node/selector/goblin_tree/New()
    ..()
    children = list(
        // Check faction tasks FIRST (when idle)
        new /datum/behavior_tree/node/selector/faction_ai_branch(),

        // Then do normal goblin stuff
        new /datum/behavior_tree/node/decorator/goblin_update_squad_data(),
        new /datum/behavior_tree/node/selector/goblin_combat(),
        new /datum/behavior_tree/node/selector/goblin_idle()
    )
```

## How It Works

1. **Subsystem fires** (every 5 seconds):
   - Wood gatherer faction gains 15 director points
   - Evaluates goals: "Gather Wood" scores based on current wood stockpile
   - If score is high enough and has 30 points, activates "Gather Wood" goal
   - Goal creates 3 wood gathering tasks and adds them to task queue

2. **Goblin behavior tree runs** (every tick for active goblins):
   - Goblin checks faction AI branch (high priority)
   - Sees it has a faction director assigned
   - Checks if it has a current faction task - no
   - Checks if it's idle (not in combat) - yes
   - Requests a task from faction director
   - Gets a "Gather Wood" task
   - Executes task: finds tree, moves to tree, gathers wood
   - When done, adds wood to faction stockpile

3. **Spawning happens**:
   - Faction now has 100+ wood and 150+ director points
   - "Spawn Wood Goblin" goal scores highly
   - Goal activates, spends 100 wood and 150 points
   - New goblin spawns at faction home base
   - New goblin is assigned to the faction
   - New goblin can also gather wood

## Result

You get emergent behavior:
- Goblins gather wood when idle
- Faction spawns more goblins when it has resources
- More goblins = more wood gathering = faster spawning
- System self-balances (caps at 10 goblins)
- Goblins still do combat and other behaviors when needed

## Extending This Example

### Add competing factions:
```dm
// Sea goblins raid wood gatherers
/faction_goal/raid_wood_gatherers
    activation_cost = 200
    base_score = 150

/faction_goal/raid_wood_gatherers/CalculateScore(faction_director/director)
    var/faction_director/wood_gatherers = SSfaction_ai.GetFaction("wood_gatherers")
    if(!wood_gatherers)
        return 0

    // Raid if they have lots of wood
    var/their_wood = wood_gatherers.GetResource("wood")
    if(their_wood > 150)
        return base_score + their_wood

    return 0

/faction_goal/raid_wood_gatherers/OnActivate(faction_director/director)
    . = ..()
    // Create raid tasks that target wood gatherer goblins
```

### Add building/fortifications:
```dm
/faction_goal/build_palisade
    activation_cost = 100
    base_score = 70

/faction_goal/build_palisade/CanActivate(faction_director/director)
    return director.GetResource("wood") >= 200

/faction_goal/build_palisade/OnActivate(faction_director/director)
    . = ..()
    if(director.SpendResource("wood", 200))
        // Spawn palisade wall at home base
        new /obj/structure/barricade/wooden(director.faction_home_base)
```

### Add seasonal behavior:
```dm
/faction_goal/gather_wood_goal/CalculateScore(faction_director/director)
    var/base = ..()

    // Gather more wood in fall to prepare for winter
    if(GLOB.season == SEASON_FALL)
        base *= 2

    return base
```
