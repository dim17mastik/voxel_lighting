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

class_name LightMapMaker
extends Node


const WIDTH := Chunk.WIDTH + 2
const MAX := WIDTH - 1

@onready var _manager := $"../ChunkManager" as ChunkManager


func _get_neighbour(chunk: Chunk, offset: Vector3i) -> Chunk:
	return _manager.chunks.get(chunk.chunk_position + offset) as Chunk


func _to_color(voxel: int) -> Color:
	return Color8(
			Chunk.get_red(voxel), Chunk.get_green(voxel), Chunk.get_blue(voxel)
	)


func create_light_map_texture(chunk: Chunk) -> void:
	var time_start := Time.get_ticks_msec()

	var chunk_000 := _get_neighbour(chunk, Vector3i(-1, -1, -1))
	var chunk_001 := _get_neighbour(chunk, Vector3i(-1, -1, 0))
	var chunk_002 := _get_neighbour(chunk, Vector3i(-1, -1, 1))
	var chunk_010 := _get_neighbour(chunk, Vector3i(-1, 0, -1))
	var chunk_011 := _get_neighbour(chunk, Vector3i(-1, 0, 0))
	var chunk_012 := _get_neighbour(chunk, Vector3i(-1, 0, 1))
	var chunk_020 := _get_neighbour(chunk, Vector3i(-1, 1, -1))
	var chunk_021 := _get_neighbour(chunk, Vector3i(-1, 1, 0))
	var chunk_022 := _get_neighbour(chunk, Vector3i(-1, 1, 1))
	var chunk_100 := _get_neighbour(chunk, Vector3i(0, -1, -1))
	var chunk_101 := _get_neighbour(chunk, Vector3i(0, -1, 0))
	var chunk_102 := _get_neighbour(chunk, Vector3i(0, -1, 1))
	var chunk_110 := _get_neighbour(chunk, Vector3i(0, 0, -1))
	var chunk_112 := _get_neighbour(chunk, Vector3i(0, 0, 1))
	var chunk_120 := _get_neighbour(chunk, Vector3i(0, 1, -1))
	var chunk_121 := _get_neighbour(chunk, Vector3i(0, 1, 0))
	var chunk_122 := _get_neighbour(chunk, Vector3i(0, 1, 1))
	var chunk_200 := _get_neighbour(chunk, Vector3i(1, -1, -1))
	var chunk_201 := _get_neighbour(chunk, Vector3i(1, -1, 0))
	var chunk_202 := _get_neighbour(chunk, Vector3i(1, -1, 1))
	var chunk_210 := _get_neighbour(chunk, Vector3i(1, 0, -1))
	var chunk_211 := _get_neighbour(chunk, Vector3i(1, 0, 0))
	var chunk_212 := _get_neighbour(chunk, Vector3i(1, 0, 1))
	var chunk_220 := _get_neighbour(chunk, Vector3i(1, 1, -1))
	var chunk_221 := _get_neighbour(chunk, Vector3i(1, 1, 0))
	var chunk_222 := _get_neighbour(chunk, Vector3i(1, 1, 1))

	var images := chunk.images

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_000) and chunk_000:
		images[0].set_pixel(0, 0, _to_color(
				chunk_000.get_voxel(Chunk.MAX, Chunk.MAX, Chunk.MAX)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_001) and chunk_001:
		for z in range(1, MAX):
			images[z].set_pixel(0, 0, _to_color(
					chunk_001.get_voxel(Chunk.MAX, Chunk.MAX, z - 1)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_002) and chunk_002:
		images[MAX].set_pixel(0, 0, _to_color(
				chunk_002.get_voxel(Chunk.MAX, Chunk.MAX, 0)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_010) and chunk_010:
		for y in range(1, MAX):
			images[0].set_pixel(0, y, _to_color(
					chunk_010.get_voxel(Chunk.MAX, y - 1, Chunk.MAX)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_011) and chunk_011:
		for z in range(1, MAX):
			for y in range(1, MAX):
				images[z].set_pixel(0, y, _to_color(
						chunk_011.get_voxel(Chunk.MAX, y - 1, z - 1)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_012) and chunk_012:
		for y in range(1, MAX):
			images[MAX].set_pixel(0, y, _to_color(
					chunk_012.get_voxel(Chunk.MAX, y - 1, 0)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_020) and chunk_020:
		images[0].set_pixel(0, MAX, _to_color(
				chunk_020.get_voxel(Chunk.MAX, 0, Chunk.MAX)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_021) and chunk_021:
		for z in range(1, MAX):
			images[z].set_pixel(0, MAX, _to_color(
					chunk_021.get_voxel(Chunk.MAX, 0, z - 1)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_022) and chunk_022:
		images[MAX].set_pixel(0, MAX, _to_color(
				chunk_022.get_voxel(Chunk.MAX, 0, 0)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_100) and chunk_100:
		for x in range(1, MAX):
			images[0].set_pixel(x, 0, _to_color(
					chunk_100.get_voxel(x - 1, Chunk.MAX, Chunk.MAX)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_101) and chunk_101:
		for z in range(1, MAX):
			for x in range(1, MAX):
				images[z].set_pixel(x, 0, _to_color(
						chunk_101.get_voxel(x - 1, Chunk.MAX, z - 1)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_102) and chunk_102:
		for x in range(1, MAX):
			images[MAX].set_pixel(x, 0, _to_color(
					chunk_102.get_voxel(x - 1, Chunk.MAX, 0)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_110) and chunk_110:
		for y in range(1, MAX):
			for x in range(1, MAX):
				images[0].set_pixel(x, y, _to_color(
						chunk_110.get_voxel(x - 1, y - 1, Chunk.MAX)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_111):
		for z in range(1, MAX):
			for y in range(1, MAX):
				for x in range(1, MAX):
					images[z].set_pixel(x, y, _to_color(
							chunk.get_voxel(x - 1, y - 1, z - 1)
					))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_112) and chunk_112:
		for y in range(1, MAX):
			for x in range(1, MAX):
				images[MAX].set_pixel(x, y, _to_color(
						chunk_112.get_voxel(x - 1, y - 1, 0)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_120) and chunk_120:
		for x in range(1, MAX):
			images[0].set_pixel(x, MAX, _to_color(
					chunk_120.get_voxel(x - 1, 0, Chunk.MAX)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_121) and chunk_121:
		for z in range(1, MAX):
			for x in range(1, MAX):
				images[z].set_pixel(x, MAX, _to_color(
						chunk_121.get_voxel(x - 1, 0, z - 1)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_122) and chunk_122:
		for x in range(1, MAX):
			images[MAX].set_pixel(x, MAX, _to_color(
					chunk_122.get_voxel(x - 1, 0, 0)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_200) and chunk_200:
		images[0].set_pixel(MAX, 0, _to_color(
				chunk_200.get_voxel(0, Chunk.MAX, Chunk.MAX)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_201) and chunk_201:
		for z in range(1, MAX):
			images[z].set_pixel(MAX, 0, _to_color(
					chunk_201.get_voxel(0, Chunk.MAX, z - 1)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_202) and chunk_202:
		images[MAX].set_pixel(MAX, 0, _to_color(
				chunk_202.get_voxel(0, Chunk.MAX, 0))
		)

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_210) and chunk_210:
		for y in range(1, MAX):
			images[0].set_pixel(MAX, y, _to_color(
					chunk_210.get_voxel(0, y - 1, Chunk.MAX)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_211) and chunk_211:
		for z in range(1, MAX):
			for y in range(1, MAX):
				images[z].set_pixel(MAX, y, _to_color(
						chunk_211.get_voxel(0, y - 1, z - 1)
				))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_212) and chunk_212:
		for y in range(1, MAX):
			images[MAX].set_pixel(MAX, y, _to_color(
					chunk_212.get_voxel(0, y - 1, 0)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_220) and chunk_220:
		images[0].set_pixel(MAX, MAX, _to_color(
				chunk_220.get_voxel(0, 0, Chunk.MAX)
		))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_221) and chunk_221:
		for z in range(1, MAX):
			images[z].set_pixel(MAX, MAX, _to_color(
					chunk_221.get_voxel(0, 0, z - 1)
			))

	if (chunk.light_map_dirty_flags & Chunk.DIRTY_LIGHT_MAP_222) and chunk_222:
		images[MAX].set_pixel(MAX, MAX, _to_color(
				chunk_222.get_voxel(0, 0, 0)
		))

	chunk.light_map.update(images)

	var now := Time.get_ticks_msec()
	var elapsed := now - time_start
	print("Light map created: %d ms" % elapsed)
