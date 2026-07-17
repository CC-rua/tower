@tool
extends EditorScript

const TILESET_PATH := "res://resource/tilemap/ground.tres"
const ROAD_SOURCE_ID := 5
const TERRAIN_SET_ID := 0
const TERRAIN_ID := 0

const TOP := TileSet.CELL_NEIGHBOR_TOP_SIDE
const RIGHT := TileSet.CELL_NEIGHBOR_RIGHT_SIDE
const BOTTOM := TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
const LEFT := TileSet.CELL_NEIGHBOR_LEFT_SIDE

func _run() -> void:
	var tileset := load(TILESET_PATH) as TileSet
	if tileset == null:
		push_error("Failed to load %s" % TILESET_PATH)
		return

	if not tileset.has_source(ROAD_SOURCE_ID):
		push_error("TileSet source %d not found" % ROAD_SOURCE_ID)
		return

	_reset_terrain_sets(tileset)
	_configure_road_terrain_set(tileset)

	var atlas := tileset.get_source(ROAD_SOURCE_ID) as TileSetAtlasSource
	if atlas == null:
		push_error("Road source is not a TileSetAtlasSource")
		return

	var patterns := {
		Vector2i(0, 0): [TOP, BOTTOM],
		Vector2i(1, 0): [TOP, BOTTOM],
		Vector2i(2, 0): [TOP, BOTTOM],
		Vector2i(3, 0): [TOP, BOTTOM],
		Vector2i(4, 0): [TOP, BOTTOM],
		Vector2i(0, 1): [TOP, BOTTOM],
		Vector2i(1, 1): [TOP, BOTTOM],
		Vector2i(2, 1): [TOP, BOTTOM],
		Vector2i(3, 1): [TOP, BOTTOM],
		Vector2i(4, 1): [TOP, BOTTOM],
		Vector2i(0, 2): [LEFT, RIGHT],
		Vector2i(1, 2): [LEFT, RIGHT],
		Vector2i(2, 2): [LEFT, RIGHT],
		Vector2i(3, 2): [LEFT, RIGHT],
		Vector2i(4, 2): [LEFT, RIGHT],
		Vector2i(0, 3): [LEFT, RIGHT],
		Vector2i(1, 3): [LEFT, RIGHT],
		Vector2i(2, 3): [LEFT, RIGHT],
		Vector2i(3, 3): [LEFT, RIGHT],
		Vector2i(4, 3): [LEFT, RIGHT],
		Vector2i(0, 4): [TOP, LEFT],
		Vector2i(1, 4): [TOP, RIGHT],
		Vector2i(2, 4): [BOTTOM, LEFT],
		Vector2i(3, 4): [BOTTOM, RIGHT],
		Vector2i(4, 4): [TOP, RIGHT],
		Vector2i(5, 0): [LEFT, RIGHT, BOTTOM],
		Vector2i(6, 0): [LEFT, RIGHT, BOTTOM],
		Vector2i(7, 0): [LEFT, RIGHT, BOTTOM],
		Vector2i(8, 0): [LEFT, RIGHT, BOTTOM],
		Vector2i(9, 0): [LEFT, RIGHT, BOTTOM],
		Vector2i(5, 1): [TOP, LEFT, BOTTOM],
		Vector2i(6, 1): [TOP, LEFT, BOTTOM],
		Vector2i(7, 1): [TOP, LEFT, BOTTOM],
		Vector2i(8, 1): [TOP, LEFT, BOTTOM],
		Vector2i(9, 1): [TOP, LEFT, BOTTOM],
		Vector2i(5, 2): [TOP, LEFT, RIGHT],
		Vector2i(6, 2): [TOP, LEFT, RIGHT],
		Vector2i(7, 2): [TOP, LEFT, RIGHT],
		Vector2i(8, 2): [TOP, LEFT, RIGHT],
		Vector2i(9, 2): [TOP, LEFT, RIGHT],
		Vector2i(5, 3): [TOP, RIGHT, BOTTOM],
		Vector2i(6, 3): [TOP, RIGHT, BOTTOM],
		Vector2i(7, 3): [TOP, RIGHT, BOTTOM],
		Vector2i(8, 3): [TOP, RIGHT, BOTTOM],
		Vector2i(9, 3): [TOP, RIGHT, BOTTOM],
		Vector2i(5, 4): [TOP, RIGHT, BOTTOM, LEFT],
		Vector2i(6, 4): [TOP, RIGHT, BOTTOM, LEFT],
		Vector2i(7, 4): [TOP, RIGHT, BOTTOM, LEFT],
		Vector2i(8, 4): [TOP, RIGHT, BOTTOM, LEFT],
		Vector2i(9, 4): [TOP, RIGHT, BOTTOM, LEFT],
	}

	for coords in patterns.keys():
		_configure_tile(atlas, coords, patterns[coords])

	var save_err := ResourceSaver.save(tileset, TILESET_PATH)
	if save_err != OK:
		push_error("Failed to save %s: %s" % [TILESET_PATH, error_string(save_err)])
		return

	print("Configured road terrain set in %s" % TILESET_PATH)
	get_editor_interface().get_resource_filesystem().scan()


func _reset_terrain_sets(tileset: TileSet) -> void:
	while tileset.get_terrain_sets_count() > 0:
		tileset.remove_terrain_set(tileset.get_terrain_sets_count() - 1)


func _configure_road_terrain_set(tileset: TileSet) -> void:
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(TERRAIN_SET_ID, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tileset.add_terrain(TERRAIN_SET_ID)
	tileset.set_terrain_name(TERRAIN_SET_ID, TERRAIN_ID, "Road")
	tileset.set_terrain_color(TERRAIN_SET_ID, TERRAIN_ID, Color(0.82, 0.75, 0.60, 1.0))


func _configure_tile(atlas: TileSetAtlasSource, coords: Vector2i, connected_sides: Array) -> void:
	var tile_data := atlas.get_tile_data(coords, 0)
	if tile_data == null:
		push_warning("Missing tile data at %s" % coords)
		return

	tile_data.terrain_set = TERRAIN_SET_ID
	tile_data.terrain = TERRAIN_ID

	for peering_bit in range(16):
		if tile_data.is_valid_terrain_peering_bit(peering_bit):
			tile_data.set_terrain_peering_bit(peering_bit, -1)

	for side in connected_sides:
		if tile_data.is_valid_terrain_peering_bit(side):
			tile_data.set_terrain_peering_bit(side, TERRAIN_ID)
