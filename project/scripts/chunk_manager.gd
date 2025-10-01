# MIT License
#
# Copyright (c) 2025 Dmitry Slabzheninov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name ChunkManager
extends Node


var chunks: Dictionary[Vector3i, Chunk]
var _chunk_scene := load("res://scenes/chunk.tscn") as PackedScene
var _thread := Thread.new()
var _running := true
var _mutex := Mutex.new()
var _player_position := Vector3.ZERO
var _thread_player_position := Vector3.ZERO
@onready var _player := get_tree().get_first_node_in_group("player") as Player
@onready var _chunks_node := $"../Chunks" as Node3D
@onready var _generator := $"../Generator" as Generator
@onready var _mesher := $"../Mesher" as Mesher
@onready var _light_propagator := $"../LightPropagator" as LightPropagator
@onready var _light_map_maker :=  $"../LightMapMaker" as LightMapMaker


func _ready() -> void:
	_thread.start(_update)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		_mutex.lock()
		_running = false
		_mutex.unlock()
		_thread.wait_to_finish()
		get_tree().quit()


func _process(_delta: float) -> void:
	_mutex.lock()
	_player_position = _player.global_position
	_mutex.unlock()


func _in_player_view(position: Vector3i) -> bool:
	var center := (Vector3(position) + Vector3.ONE * 0.5) * Chunk.WIDTH
	var distance := _thread_player_position.distance_squared_to(center)
	return distance <= _player.view_distance * _player.view_distance


func _remove_chunk(position: Vector3i) -> void:
	var chunk := chunks[position]
	chunks.erase(position)
	_chunks_node.remove_child.call_deferred(chunk)
	chunk.queue_free()
	print("Removed %d, %d, %d" % [position.x, position.y, position.z])


func _remove_far_chunks() -> void:
	for position in chunks:
		if not _in_player_view(position):
			_remove_chunk(position)


func _create_chunk(position: Vector3i) -> void:
	var chunk := _chunk_scene.instantiate() as Chunk
	chunk.name = "Chunk(%d,%d,%d)" % [position.x, position.y, position.z]
	chunk.position = Vector3(position) * Chunk.WIDTH
	chunk.chunk_position = position
	chunks[position] = chunk
	_chunks_node.add_child.call_deferred(chunk)
	print("Created %d, %d, %d" % [position.x, position.y, position.z])


func _create_close_chunks() -> void:
	var start := Vector3i((
			_thread_player_position - Vector3.ONE * _player.view_distance
	) / Chunk.WIDTH)
	var end := Vector3i((
			_thread_player_position + Vector3.ONE * _player.view_distance
	) / Chunk.WIDTH)
	for z in range(start.z, end.z + 1):
		for y in range(start.y, end.y + 1):
			for x in range(start.x, end.x + 1):
				var position := Vector3i(x, y, z)
				if _in_player_view(position) and not position in chunks:
					_create_chunk(position)


func _get_neighbour(chunk: Chunk, offset: Vector3i) -> Chunk:
	return chunks.get(chunk.chunk_position + offset) as Chunk


func _update_chunk(chunk: Chunk) -> void:
	var chunk_011 := _get_neighbour(chunk, Vector3i(-1, 0, 0))
	var chunk_211 := _get_neighbour(chunk, Vector3i(1, 0, 0))
	var chunk_101 := _get_neighbour(chunk, Vector3i(0, -1, 0))
	var chunk_121 := _get_neighbour(chunk, Vector3i(0, 1, 0))
	var chunk_110 := _get_neighbour(chunk, Vector3i(0, 0, -1))
	var chunk_112 := _get_neighbour(chunk, Vector3i(0, 0, 1))

	if chunk.dirty_flags & Chunk.DIRTY_VOXELS:
		_generator.generate_data(chunk)
		chunk.dirty_flags &= ~Chunk.DIRTY_VOXELS

		if chunk_011:
			chunk_011.dirty_flags |= Chunk.DIRTY_MESH

		if chunk_211:
			chunk_211.dirty_flags |= Chunk.DIRTY_MESH

		if chunk_101:
			chunk_101.dirty_flags |= Chunk.DIRTY_MESH

		if chunk_121:
			chunk_121.dirty_flags |= Chunk.DIRTY_MESH

		if chunk_110:
			chunk_110.dirty_flags |= Chunk.DIRTY_MESH

		if chunk_112:
			chunk_112.dirty_flags |= Chunk.DIRTY_MESH

	if chunk.dirty_flags & Chunk.DIRTY_MESH:
		_mesher.create_mesh(chunk)
		chunk.dirty_flags &= ~Chunk.DIRTY_MESH

	var should_propagate := (
			not chunk.init_queue.is_empty() or
			chunk_011 and not chunk_011.right_queue.is_empty() or
			chunk_011 and not chunk_011.right_queue.is_empty() or
			chunk_011 and not chunk_011.right_queue.is_empty() or
			chunk_211 and not chunk_211.left_queue.is_empty() or
			chunk_101 and not chunk_101.up_queue.is_empty() or
			chunk_121 and not chunk_121.down_queue.is_empty() or
			chunk_110 and not chunk_110.back_queue.is_empty() or
			chunk_112 and not chunk_112.forward_queue.is_empty()
	)

	if should_propagate:
		var light_map_modified := (
				_light_propagator.propagate_internal_sources(chunk)
		)
		chunk.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_111

		if light_map_modified:
			if chunk_011:
				chunk_011.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_211

			if chunk_211:
				chunk_211.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_011

			if chunk_101:
				chunk_101.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_121

			if chunk_121:
				chunk_121.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_101

			if chunk_110:
				chunk_110.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_112

			if chunk_112:
				chunk_112.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_110

			var chunk_001 := _get_neighbour(chunk, Vector3i(-1, -1, 0))
			if chunk_001:
				chunk_001.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_221

			var chunk_021 := _get_neighbour(chunk, Vector3i(-1, 1, 0))
			if chunk_021:
				chunk_021.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_201

			var chunk_201 := _get_neighbour(chunk, Vector3i(1, -1, 0))
			if chunk_201:
				chunk_201.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_021

			var chunk_221 := _get_neighbour(chunk, Vector3i(1, 1, 0))
			if chunk_221:
				chunk_221.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_001

			var chunk_010 := _get_neighbour(chunk, Vector3i(-1, 0, -1))
			if chunk_010:
				chunk_010.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_212

			var chunk_012 := _get_neighbour(chunk, Vector3i(-1, 0, 1))
			if chunk_012:
				chunk_012.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_210

			var chunk_210 := _get_neighbour(chunk, Vector3i(1, 0, -1))
			if chunk_210:
				chunk_210.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_012

			var chunk_212 := _get_neighbour(chunk, Vector3i(1, 0, 1))
			if chunk_212:
				chunk_212.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_010

			var chunk_100 := _get_neighbour(chunk, Vector3i(0, -1, -1))
			if chunk_100:
				chunk_100.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_122

			var chunk_102 := _get_neighbour(chunk, Vector3i(0, -1, 1))
			if chunk_102:
				chunk_102.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_120

			var chunk_120 := _get_neighbour(chunk, Vector3i(0, 1, -1))
			if chunk_120:
				chunk_120.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_102

			var chunk_122 := _get_neighbour(chunk, Vector3i(0, 1, 1))
			if chunk_122:
				chunk_122.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_100

			var chunk_000 := _get_neighbour(chunk, Vector3i(-1, -1, -1))
			if chunk_000:
				chunk_000.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_222

			var chunk_200 := _get_neighbour(chunk, Vector3i(1, -1, -1))
			if chunk_200:
				chunk_200.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_022

			var chunk_020 := _get_neighbour(chunk, Vector3i(-1, 1, -1))
			if chunk_020:
				chunk_020.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_202

			var chunk_220 := _get_neighbour(chunk, Vector3i(1, 1, -1))
			if chunk_220:
				chunk_220.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_002

			var chunk_002 := _get_neighbour(chunk, Vector3i(-1, -1, 1))
			if chunk_002:
				chunk_002.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_220

			var chunk_202 := _get_neighbour(chunk, Vector3i(1, -1, 1))
			if chunk_202:
				chunk_202.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_020

			var chunk_022 := _get_neighbour(chunk, Vector3i(-1, 1, 1))
			if chunk_022:
				chunk_022.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_200

			var chunk_222 := _get_neighbour(chunk, Vector3i(1, 1, 1))
			if chunk_222:
				chunk_222.light_map_dirty_flags |= Chunk.DIRTY_LIGHT_MAP_000

	if chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_ALL:
		_light_map_maker.create_light_map_texture(chunk)
		chunk.light_map_dirty_flags = 0


func _update_chunks() -> void:
	for chunk in chunks.values() as Array[Chunk]:
		_update_chunk(chunk)


func _update() -> void:
	while true:
		var time_start := Time.get_ticks_msec()

		_mutex.lock()
		if not _running:
			_mutex.unlock()
			return
		_thread_player_position = _player_position
		_mutex.unlock()

		_remove_far_chunks()
		_create_close_chunks()
		_update_chunks()

		var now := Time.get_ticks_msec()
		var elapsed := now - time_start
		if elapsed < 2:
			OS.delay_msec(8)
