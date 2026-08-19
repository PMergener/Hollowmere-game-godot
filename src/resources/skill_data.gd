class_name SkillData
extends Resource

## One line in the skill menu, bought with soul embers.

@export var id: StringName = &""
@export var display_name: String = "Unnamed skill"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Cost")
@export var base_cost: int = 30
## Every rank already owned - of ANY skill - makes the next purchase this much
## dearer, compounding. 1.2 is a fifth more each time.
@export var cost_inflation: float = 1.2
@export_range(1, 10) var max_rank: int = 2

@export_group("Effect")
## What the skill changes. The player reads this to decide what to apply the
## magnitude to.
@export var effect: StringName = &""
## How much, per rank.
@export var magnitude_per_rank: float = 0.0
