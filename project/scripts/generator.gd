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

class_name Generator
extends Node


@export var _stone_noise: FastNoiseLite
@export var _lamp_noise: FastNoiseLite
@export var _red_noise: FastNoiseLite
@export var _green_noise: FastNoiseLite
@export var _blue_noise: FastNoiseLite


func _generate_voxel(
		chunk: Chunk, offset: Vector3, x: int, y: int, z: int
) -> void:
	var position := offset + Vector3(x, y, z)
	var type := Chunk.AIR
	var red := 0
	var green := 0
	var blue := 0
	if _stone_noise.get_noise_3dv(position) > 0.0:
		type = Chunk.STONE
	elif _lamp_noise.get_noise_3dv(position) > 0.4:
		if (
				_stone_noise.get_noise_3dv(position + Vector3.LEFT) > 0.0 or
				_stone_noise.get_noise_3dv(position + Vector3.RIGHT) > 0.0 or
				_stone_noise.get_noise_3dv(position + Vector3.DOWN) > 0.0 or
				_stone_noise.get_noise_3dv(position + Vector3.UP) > 0.0 or
				_stone_noise.get_noise_3dv(position + Vector3.FORWARD) > 0.0 or
				_stone_noise.get_noise_3dv(position + Vector3.BACK) > 0.0
		):
			type = Chunk.LAMP
			red = roundi((
					_red_noise.get_noise_3dv(position) + 1.0) * 0.5 * 255.0
			)
			green = roundi((
					_green_noise.get_noise_3dv(position) + 1.0) * 0.5 * 255.0
			)
			blue = roundi((
					_blue_noise.get_noise_3dv(position) + 1.0) * 0.5 * 255.0
			)
			if red > 15 or green > 15 or blue > 15:
				chunk.init_queue.append(Chunk.pack_coords(x, y, z))
	var voxel := Chunk.create_voxel(type, red, green, blue)
	chunk.set_voxel(x, y, z, voxel)


func generate_data(chunk: Chunk) -> void:
	var _time_start := Time.get_ticks_msec()

	var offset := Vector3(chunk.chunk_position) * Chunk.WIDTH
	for z in Chunk.WIDTH:
		for y in Chunk.WIDTH:
			for x in Chunk.WIDTH:
				_generate_voxel(chunk, offset, x, y, z)

	var now := Time.get_ticks_msec()
	var elapsed := now - _time_start
	print("Generated: %d ms" % elapsed)
