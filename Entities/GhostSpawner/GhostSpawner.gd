extends Node2D

var tilemap;
var tree_tilemap;

export var spawn_area : Rect2 = Rect2(50, 150, 700, 700);
export var max_ghosts = 40;
export var start_ghosts = 10;
var ghost_count = 0;
var ghost_scene = preload("res://Entities/Ghost/Ghost.tscn");

var rng = RandomNumberGenerator.new();

func _ready():
	tilemap = get_tree().root.get_node("Root/FloorBack");
	
	rng.randomize();
	
	for i in range(start_ghosts):
		instance_ghost();
	ghost_count = start_ghosts;

func instance_ghost():
	var ghost = ghost_scene.instance();
	add_child(ghost);
	
	ghost.connect("death", self, "_on_Ghost_death");
	
	var valid_position = false;
	while not valid_position:
		ghost.position.x = spawn_area.position.x + rng.randf_range(0, spawn_area.size.x);
		ghost.position.y = 144;
		valid_position = test_position(ghost.position);
	
	ghost.arise();


func _on_Ghost_death():
	ghost_count -= 1;


func test_position(position: Vector2):
	var cell_coord = tilemap.world_to_map(position);
	var cell_type_id = tilemap.get_cellv(cell_coord);
	var tile = (cell_type_id == tilemap.tile_set.find_tile_by_name("FloorTop"));
	
	return tile;


func _on_Timer_timeout() -> void:
	if ghost_count < max_ghosts:
		instance_ghost();
		ghost_count += 1;
