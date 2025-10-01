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

class_name Mesher
extends Node


@onready var _manager := $"../ChunkManager" as ChunkManager


func _get_neighbour(chunk: Chunk, offset: Vector3i) -> Chunk:
	return _manager.chunks.get(chunk.chunk_position + offset)


func _add_uv(uv: PackedVector2Array, type: int) -> void:
	if type == Chunk.STONE:
		uv.append(Vector2(0.0, 0.5))
		uv.append(Vector2(0.0, 0.0))
		uv.append(Vector2(0.5, 0.0))
		uv.append(Vector2(0.5, 0.5))
	elif type == Chunk.LAMP:
		uv.append(Vector2(0.5, 0.5))
		uv.append(Vector2(0.5, 0.0))
		uv.append(Vector2(1.0, 0.0))
		uv.append(Vector2(1.0, 0.5))


func _add_indices(vertex_count: int, indices: PackedInt32Array) -> void:
	var offset := vertex_count - 4
	indices.append(offset + 0)
	indices.append(offset + 1)
	indices.append(offset + 2)
	indices.append(offset + 2)
	indices.append(offset + 3)
	indices.append(offset + 0)


func create_mesh(chunk: Chunk) -> void:
	var time_start := Time.get_ticks_msec()

	var vertices: PackedVector3Array
	var normals: PackedVector3Array
	var uv: PackedVector2Array
	var indices: PackedInt32Array

	var left_chunk := _get_neighbour(chunk, Vector3i.LEFT)
	var right_chunk := _get_neighbour(chunk, Vector3i.RIGHT)
	var down_chunk := _get_neighbour(chunk, Vector3i.DOWN)
	var up_chunk := _get_neighbour(chunk, Vector3i.UP)
	var forward_chunk := _get_neighbour(chunk, Vector3i.FORWARD)
	var back_chunk := _get_neighbour(chunk, Vector3i.BACK)

	for z in Chunk.WIDTH:
		for y in Chunk.WIDTH:
			for x in Chunk.WIDTH:
				var type := Chunk.get_type(chunk.get_voxel(x, y, z))

				if type == Chunk.AIR:
					continue

				var offset := Vector3(x, y, z)

				var neighbour := Chunk.AIR
				if x > 0:
					neighbour = Chunk.get_type(chunk.get_voxel(x - 1, y, z))
				elif left_chunk:
					neighbour = Chunk.get_type(
							left_chunk.get_voxel(Chunk.MAX, y, z)
					)

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(0.0, 0.0, 0.0))
					vertices.append(offset + Vector3(0.0, 1.0, 0.0))
					vertices.append(offset + Vector3(0.0, 1.0, 1.0))
					vertices.append(offset + Vector3(0.0, 0.0, 1.0))
					normals.append(Vector3.LEFT)
					normals.append(Vector3.LEFT)
					normals.append(Vector3.LEFT)
					normals.append(Vector3.LEFT)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

				neighbour = Chunk.AIR
				if x < Chunk.MAX:
					neighbour = Chunk.get_type(chunk.get_voxel(x + 1, y, z))
				elif right_chunk:
					neighbour = Chunk.get_type(right_chunk.get_voxel(0, y, z))

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(1.0, 0.0, 1.0))
					vertices.append(offset + Vector3(1.0, 1.0, 1.0))
					vertices.append(offset + Vector3(1.0, 1.0, 0.0))
					vertices.append(offset + Vector3(1.0, 0.0, 0.0))
					normals.append(Vector3.RIGHT)
					normals.append(Vector3.RIGHT)
					normals.append(Vector3.RIGHT)
					normals.append(Vector3.RIGHT)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

				neighbour = Chunk.AIR
				if y > 0:
					neighbour = Chunk.get_type(chunk.get_voxel(x, y - 1, z))
				elif down_chunk:
					neighbour = Chunk.get_type(
							down_chunk.get_voxel(x, Chunk.MAX, z)
					)

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(0.0, 0.0, 0.0))
					vertices.append(offset + Vector3(0.0, 0.0, 1.0))
					vertices.append(offset + Vector3(1.0, 0.0, 1.0))
					vertices.append(offset + Vector3(1.0, 0.0, 0.0))
					normals.append(Vector3.DOWN)
					normals.append(Vector3.DOWN)
					normals.append(Vector3.DOWN)
					normals.append(Vector3.DOWN)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

				neighbour = Chunk.AIR
				if y < Chunk.MAX:
					neighbour = Chunk.get_type(chunk.get_voxel(x, y + 1, z))
				elif up_chunk:
					neighbour = Chunk.get_type(up_chunk.get_voxel(x, 0, z))

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(0.0, 1.0, 1.0))
					vertices.append(offset + Vector3(0.0, 1.0, 0.0))
					vertices.append(offset + Vector3(1.0, 1.0, 0.0))
					vertices.append(offset + Vector3(1.0, 1.0, 1.0))
					normals.append(Vector3.UP)
					normals.append(Vector3.UP)
					normals.append(Vector3.UP)
					normals.append(Vector3.UP)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

				neighbour = Chunk.AIR
				if z > 0:
					neighbour = Chunk.get_type(chunk.get_voxel(x, y, z - 1))
				elif forward_chunk:
					neighbour = Chunk.get_type(
							forward_chunk.get_voxel(x, y, Chunk.MAX)
					)

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(1.0, 0.0, 0.0))
					vertices.append(offset + Vector3(1.0, 1.0, 0.0))
					vertices.append(offset + Vector3(0.0, 1.0, 0.0))
					vertices.append(offset + Vector3(0.0, 0.0, 0.0))
					normals.append(Vector3.FORWARD)
					normals.append(Vector3.FORWARD)
					normals.append(Vector3.FORWARD)
					normals.append(Vector3.FORWARD)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

				neighbour = Chunk.AIR
				if z < Chunk.MAX:
					neighbour = Chunk.get_type(chunk.get_voxel(x, y, z + 1))
				elif back_chunk:
					neighbour = Chunk.get_type(back_chunk.get_voxel(x, y, 0))

				if neighbour == Chunk.AIR:
					vertices.append(offset + Vector3(0.0, 0.0, 1.0))
					vertices.append(offset + Vector3(0.0, 1.0, 1.0))
					vertices.append(offset + Vector3(1.0, 1.0, 1.0))
					vertices.append(offset + Vector3(1.0, 0.0, 1.0))
					normals.append(Vector3.BACK)
					normals.append(Vector3.BACK)
					normals.append(Vector3.BACK)
					normals.append(Vector3.BACK)
					_add_uv(uv, type)
					_add_indices(vertices.size(), indices)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices

	if not chunk.mesh_instance.mesh:
		if not vertices.is_empty():
			var mesh := ArrayMesh.new()
			chunk.mesh_instance.set_mesh.call_deferred(mesh)
			mesh.add_surface_from_arrays.call_deferred(
					Mesh.PRIMITIVE_TRIANGLES, arrays
			)
			mesh.surface_set_material.call_deferred(0, chunk.material)
	else:
		var mesh := chunk.mesh_instance.mesh as ArrayMesh
		mesh.surface_remove.call_deferred(0)
		mesh.add_surface_from_arrays.call_deferred(
				Mesh.PRIMITIVE_TRIANGLES, arrays
		)
		mesh.surface_set_material.call_deferred(0, chunk.material)

	var now := Time.get_ticks_msec()
	var elapsed := now - time_start
	print("Mesh created: %d ms" % elapsed)
