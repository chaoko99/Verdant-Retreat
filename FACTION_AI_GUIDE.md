# Faction AI Director System

## Overview

The Faction AI Director system provides high-level strategic AI for managing groups of NPCs. It handles resource management, goal-based decision making, and task distribution using a GOAP-style (Goal-Oriented Action Planning) point system similar to the Left 4 Dead 2 AI Director.

## Architecture

### Components

1. **SSfaction_ai** - Subsystem that processes all faction directors every 5 seconds
2. **faction_director** - Datum representing a single faction's AI brain
3. **faction_goal** - Represents high-level objectives (gather resources, spawn units, raid)
4. **faction_task** - Individual tasks that can be assigned to mobs
5. **Behavior Tree Integration** - Nodes for mobs to request and execute faction tasks

## Core Concepts

### Director Points

Similar to L4D2's Director system, factions accumulate points over time that can be spent on actions:

- Points accumulate each processing cycle (default: 10 points per 5 seconds)
- Goals have activation costs
- Prevents spamming of high-priority actions
- Creates more dynamic, paced gameplay

### Goal Scoring System

Goals calculate priority scores each cycle based on faction state:

```dm
/faction_goal/gather_resources/CalculateScore(faction_director/director)
    var/current = director.GetResource(resource_type)
    var/deficit = target_amount - current

    if(deficit <= 0)
        return 0 // We have enough

    // Higher deficit = higher priority
    return base_score + (deficit / 10)
```

The faction activates the highest-scoring goal that it can afford.

### Resource Management

Factions track stockpiles of resources:

- Wood, stone, food, metal (customizable)
- Resources can be spent on spawning units, building, etc.
- Resource generation can be passive or task-based

## How to Use

### 1. Create a Faction Director

```dm
/faction_director/goblin/sea
    faction_id = "sea_goblins"
    faction_name = "Sea Goblin Raiders"
    faction_tags = list("orcs")

/faction_director/goblin/sea/InitializeGoals()
    ..()
    // Add faction-specific goals
    available_goals += new /faction_goal/goblin_coastal_raid(src)
    available_goals += new /faction_goal/spawn_unit/spawn_goblin(src)
```

### 2. Create Custom Goals

```dm
/faction_goal/my_custom_goal
    goal_name = "My Custom Goal"
    activation_cost = 100
    base_score = 80

/faction_goal/my_custom_goal/CalculateScore(faction_director/director)
    // Calculate priority based on faction state
    return base_score + some_calculation

/faction_goal/my_custom_goal/Process(faction_director/director)
    // Do something each cycle while active
    // Create tasks, spend resources, etc.

/faction_goal/my_custom_goal/IsComplete(faction_director/director)
    // Return TRUE when goal is done
    return some_condition
```

### 3. Create Faction Tasks

```dm
/faction_task/gather_wood
    task_name = "Gather Wood"
    task_priority = 50
    var/amount_to_gather = 10
    var/turf/gather_location

/faction_task/gather_wood/Execute(mob/living/M)
    // This is called from the mob's behavior tree
    // Return TRUE when complete, FALSE when still working

    if(!gather_location)
        gather_location = find_nearest_tree(M)

    if(M.loc == gather_location)
        // Gather wood here
        return TRUE
    else
        // Move toward location
        M.set_ai_path_to(gather_location)
        return FALSE
```

### 4. Integrate with Behavior Trees

Add faction AI as a high-priority branch in your mob's behavior tree:

```dm
/datum/behavior_tree/node/selector/goblin_tree/New()
    ..()
    children = list(
        new /datum/behavior_tree/node/selector/faction_ai_branch(), // Faction AI
        new /datum/behavior_tree/node/selector/goblin_combat(),      // Combat
        new /datum/behavior_tree/node/selector/goblin_idle()         // Idle behavior
    )
```

### 5. Assign Faction Directors to Mobs

When spawning NPCs, assign them to a faction:

```dm
/mob/living/carbon/human/species/goblin/npc/sea/Initialize()
    . = ..()

    // Get or create the sea goblin faction
    var/faction_director/director = SSfaction_ai.GetFaction("sea_goblins")
    if(!director)
        director = new /faction_director/goblin/sea()

    // Assign to this mob
    ai_root.blackboard[AIBLK_FACTION_DIRECTOR] = director
```

## Example: Sea Goblins vs Cave Goblins

### Sea Goblins

- **Resources**: Food (from fishing), scrap (from raids)
- **Goals**: Raid coastal settlements, spawn raiders, scavenge shipwrecks
- **Behavior**: Aggressive, spawn frequently when fed
- **Spawning**: Costs 40 food, 80 director points per goblin

### Cave Goblins

- **Resources**: Stone (from mining), metal (from ore), wood
- **Goals**: Gather stone/metal, fortify caves, spawn miners
- **Behavior**: Defensive, focus on resource gathering
- **Spawning**: Costs 100 stone, 120 director points per goblin

### Rivalry Dynamics

You could create inter-faction conflict:

```dm
/faction_goal/attack_rival_faction
    goal_name = "Attack Rival Faction"
    activation_cost = 300
    base_score = 150
    var/rival_faction_id

/faction_goal/attack_rival_faction/CalculateScore(faction_director/director)
    var/faction_director/rival = SSfaction_ai.GetFaction(rival_faction_id)
    if(!rival)
        return 0

    // Attack if we have more units than rival
    var/our_units = 0
    var/their_units = 0

    for(var/count in director.current_units)
        our_units += director.current_units[count]
    for(var/count in rival.current_units)
        their_units += rival.current_units[count]

    if(our_units > their_units * 1.5)
        return base_score + (our_units - their_units) * 10

    return 0
```

## Simulating Resource Gathering

For a full simulation, you can have mobs actually gather resources:

```dm
/faction_task/gather/Execute(mob/living/M)
    if(!gather_location)
        // Find a resource node
        gather_location = find_resource_node(resource_type, M)
        if(!gather_location)
            return TRUE // No resources found, complete task

    if(get_dist(M, gather_location) > 1)
        // Move to resource
        M.set_ai_path_to(gather_location)
        return FALSE

    // At resource, gather it
    var/obj/structure/resource_node/node = gather_location
    if(!node || QDELETED(node))
        return TRUE // Node gone

    node.harvest(M, amount_to_gather)

    // Add to faction stockpile
    var/faction_director/director = M.ai_root.blackboard[AIBLK_FACTION_DIRECTOR]
    if(director)
        director.AddResource(resource_type, amount_to_gather)

    return TRUE // Complete
```

## Performance Considerations

- Faction AI processes every 5 seconds (much slower than individual mob AI)
- Faction directors use point budgets to prevent spam
- Tasks are queued and distributed on-demand
- Mob behavior trees only check faction tasks when idle

## Future Expansion Ideas

- **Territory Control**: Factions claim and defend areas
- **Diplomacy**: Factions can ally or go to war
- **Tech Trees**: Unlock better units/buildings with resources
- **Dynamic Spawning**: Spawn points can be captured/destroyed
- **Supply Lines**: Resources need to be transported
- **Morale System**: Faction strength affects unit behavior
- **Seasonal Behavior**: Different goals in different seasons

## Debugging

Check faction state in-game:

```dm
// View all factions
for(var/faction_director/F in SSfaction_ai.factions)
    to_chat(usr, "[F.faction_name]: [F.director_points] points")
    for(var/res in F.resources)
        to_chat(usr, "  [res]: [F.resources[res]]")
```

## Files Reference

- `code/controllers/subsystem/faction_ai.dm` - Main subsystem and base classes
- `code/datums/ai/behavior_tree/actions_faction.dm` - Behavior tree integration
- `code/datums/ai/faction_directors/goblin_faction.dm` - Example goblin implementation
- `code/__DEFINES/ai/behavior_tree.dm` - Blackboard key defines

## API Reference

### Faction Director Methods

- `AddResource(type, amount)` - Add resources to stockpile
- `SpendResource(type, amount)` - Spend resources (returns success)
- `GetResource(type)` - Get current resource amount
- `SpendPoints(amount)` - Spend director points (returns success)
- `RequestTask(mob)` - Get a task for a mob to execute
- `AddTask(task)` - Add a task to the pending queue
- `SpawnUnit(mob_type, location)` - Spawn a unit for this faction
- `IsFactionMember(mob)` - Check if mob belongs to faction

### Subsystem Methods

- `SSfaction_ai.GetFaction(faction_id)` - Get faction by ID
- `SSfaction_ai.RegisterFaction(director)` - Register a faction
- `SSfaction_ai.UnregisterFaction(director)` - Unregister a faction
