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

class_name LightPropagator
extends Node


@onready var _manager := $"../ChunkManager" as ChunkManager


func _get_neighbour(chunk: Chunk, offset: Vector3i) -> Chunk:
	return _manager.chunks.get(chunk.chunk_position + offset) as Chunk


func _propagate_light_to_voxel(
		dest_chunk: Chunk, queue: PackedInt32Array, x: int, y: int, z: int,
		src_voxel: int
) -> bool:
	var dest_voxel := dest_chunk.get_voxel(x, y, z)
	var dest_type := Chunk.get_type(dest_voxel)

	if dest_type != Chunk.AIR:
		return false

	var src_red := Chunk.get_red(src_voxel)
	var src_green := Chunk.get_green(src_voxel)
	var src_blue := Chunk.get_blue(src_voxel)

	var dest_red := Chunk.get_red(dest_voxel)
	var dest_green := Chunk.get_green(dest_voxel)
	var dest_blue := Chunk.get_blue(dest_voxel)

	var should_continue := false

	if src_red - dest_red > 15:
		dest_red = src_red - 15
		should_continue = dest_red > 15

	if src_green - dest_green > 15:
		dest_green = src_green - 15
		should_continue = should_continue or dest_green > 15

	if src_blue - dest_blue > 15:
		dest_blue = src_blue - 15
		should_continue = should_continue or dest_blue > 15

	var new_voxel := Chunk.create_voxel(
			dest_type, dest_red, dest_green, dest_blue
	)

	if new_voxel != dest_voxel:
		dest_chunk.set_voxel(x, y, z, new_voxel)

	if should_continue:
		queue.append(x + y * Chunk.WIDTH + z * Chunk.AREA)

	return new_voxel != dest_voxel


func _propagate_light_between_chunks(
		src_chunk: Chunk, dest_chunk: Chunk, queue: PackedInt32Array,
		sx: int, sy: int, sz: int, dx: int, dy: int, dz: int
) -> bool:
	var voxel := src_chunk.get_voxel(sx, sy, sz)
	return _propagate_light_to_voxel(dest_chunk, queue, dx, dy, dz, voxel)


func _add_voxel_to_propagation_queue(
		queue: PackedInt32Array, x: int, y: int, z: int, voxel: int
) -> void:
	var red := Chunk.get_red(voxel)
	var green := Chunk.get_green(voxel)
	var blue := Chunk.get_blue(voxel)
	if red > 1 or green > 1 or blue > 1:
		queue.append(x + y * Chunk.WIDTH + z * Chunk.AREA)


func propagate_internal_sources(chunk: Chunk) -> bool:
	var time_start := Time.get_ticks_msec()

	var queue := chunk.init_queue.duplicate()
	chunk.init_queue.clear()

	var new_queue: PackedInt32Array

	var left_chunk := _get_neighbour(chunk, Vector3i.LEFT)
	var right_chunk := _get_neighbour(chunk, Vector3i.RIGHT)
	var down_chunk := _get_neighbour(chunk, Vector3i.DOWN)
	var up_chunk := _get_neighbour(chunk, Vector3i.UP)
	var forward_chunk := _get_neighbour(chunk, Vector3i.FORWARD)
	var back_chunk := _get_neighbour(chunk, Vector3i.BACK)

	var light_map_modified := false

	if left_chunk:
		for i in left_chunk.right_queue:
			var y := Chunk.get_y(i)
			var z := Chunk.get_z(i)
			light_map_modified = _propagate_light_between_chunks(
					left_chunk, chunk, queue, Chunk.MAX, y, z, 0, y, z
			)
		left_chunk.right_queue.clear()

	if right_chunk:
		for i in right_chunk.left_queue:
			var y := Chunk.get_y(i)
			var z := Chunk.get_z(i)
			light_map_modified = _propagate_light_between_chunks(
					right_chunk, chunk, queue, 0, y, z, Chunk.MAX, y, z
			) or light_map_modified
		right_chunk.left_queue.clear()

	if down_chunk:
		for i in down_chunk.up_queue:
			var x := Chunk.get_x(i)
			var z := Chunk.get_z(i)
			light_map_modified = _propagate_light_between_chunks(
					down_chunk, chunk, queue, x, Chunk.MAX, z, x, 0, z
			) or light_map_modified
		down_chunk.up_queue.clear()

	if up_chunk:
		for i in up_chunk.down_queue:
			var x := Chunk.get_x(i)
			var z := Chunk.get_z(i)
			light_map_modified = _propagate_light_between_chunks(
					up_chunk, chunk, queue, x, 0, z, x, Chunk.MAX, z
			) or light_map_modified
		up_chunk.down_queue.clear()

	if forward_chunk:
		for i in forward_chunk.back_queue:
			var x := Chunk.get_x(i)
			var y := Chunk.get_y(i)
			light_map_modified = _propagate_light_between_chunks(
					forward_chunk, chunk, queue, x, y, Chunk.MAX, x, y, 0
			) or light_map_modified
		forward_chunk.back_queue.clear()

	if back_chunk:
		for i in back_chunk.forward_queue:
			var x := Chunk.get_x(i)
			var y := Chunk.get_y(i)
			light_map_modified = _propagate_light_between_chunks(
					back_chunk, chunk, queue, x, y, 0, x, y, Chunk.MAX
			) or light_map_modified
		back_chunk.forward_queue.clear()

	while not queue.is_empty():
		for i in queue:
			var x := Chunk.get_x(i)
			var y := Chunk.get_y(i)
			var z := Chunk.get_z(i)

			var voxel := chunk.get_voxel(x, y, z)

			if x > 0:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x - 1, y, z, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.left_queue, x, y, z, voxel
				)

			if x < Chunk.MAX:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x + 1, y, z, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.right_queue, x, y, z, voxel
				)
				

			if y > 0:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x, y - 1, z, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.down_queue, x, y, z, voxel
				)

			if y < Chunk.MAX:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x, y + 1, z, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.up_queue, x, y, z, voxel
				)

			if z > 0:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x, y, z - 1, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.forward_queue, x, y, z, voxel
				)

			if z < Chunk.MAX:
				light_map_modified = _propagate_light_to_voxel(
						chunk, new_queue, x, y, z + 1, voxel
				) or light_map_modified
			else:
				_add_voxel_to_propagation_queue(
						chunk.back_queue, x, y, z, voxel
				)

		var tmp := queue
		queue = new_queue
		new_queue = tmp
		new_queue.clear()

	var now := Time.get_ticks_msec()
	var elapsed := now - time_start
	print("Light propagated: %d ms" % elapsed)

	return light_map_modified
