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

class_name Chunk
extends Node3D


const WIDTH := 32
const AREA := WIDTH * WIDTH
const VOLUME := AREA * WIDTH
const MAX := WIDTH - 1
const LIGHT_MAP_WIDTH := WIDTH + 2

const Y_OFFSET := floori(log(32) / log(2))
const Z_OFFSET := Y_OFFSET * 2

const TYPE_MASK := 0b11111111
const RED_OFFSET := 8
const RED_MASK := 0b11111111
const GREEN_OFFSET := 16
const GREEN_MASK := 0b11111111
const BLUE_OFFSET := 24
const BLUE_MASK := 0b11111111

const AIR := 0
const STONE := 1
const LAMP := 2

const DIRTY_VOXELS := 0b1
const DIRTY_MESH := 0b10
const DIRTY_ALL := 0b111

const DIRTY_LIGHT_MAP_000 := 1 << 0
const DIRTY_LIGHT_MAP_001 := 1 << 1
const DIRTY_LIGHT_MAP_002 := 1 << 2
const DIRTY_LIGHT_MAP_010 := 1 << 3
const DIRTY_LIGHT_MAP_011 := 1 << 4
const DIRTY_LIGHT_MAP_012 := 1 << 5
const DIRTY_LIGHT_MAP_020 := 1 << 6
const DIRTY_LIGHT_MAP_021 := 1 << 7
const DIRTY_LIGHT_MAP_022 := 1 << 8
const DIRTY_LIGHT_MAP_100 := 1 << 9
const DIRTY_LIGHT_MAP_101 := 1 << 10
const DIRTY_LIGHT_MAP_102 := 1 << 11
const DIRTY_LIGHT_MAP_110 := 1 << 12
const DIRTY_LIGHT_MAP_111 := 1 << 13
const DIRTY_LIGHT_MAP_112 := 1 << 14
const DIRTY_LIGHT_MAP_120 := 1 << 15
const DIRTY_LIGHT_MAP_121 := 1 << 16
const DIRTY_LIGHT_MAP_122 := 1 << 17
const DIRTY_LIGHT_MAP_200 := 1 << 18
const DIRTY_LIGHT_MAP_201 := 1 << 19
const DIRTY_LIGHT_MAP_202 := 1 << 20
const DIRTY_LIGHT_MAP_210 := 1 << 21
const DIRTY_LIGHT_MAP_211 := 1 << 22
const DIRTY_LIGHT_MAP_212 := 1 << 23
const DIRTY_LIGHT_MAP_220 := 1 << 24
const DIRTY_LIGHT_MAP_221 := 1 << 25
const DIRTY_LIGHT_MAP_222 := 1 << 26
const DIRTY_LIGHT_MAP_ALL := (1 << 27) - 1

var chunk_position: Vector3i
var voxels: PackedInt32Array
var dirty_flags := DIRTY_ALL
var light_map_dirty_flags := DIRTY_LIGHT_MAP_ALL
var images: Array[Image]
var light_map := ImageTexture3D.new()
var material := load("res://materials/chunk.tres").duplicate() as ShaderMaterial
var init_queue: PackedInt32Array
var left_queue: PackedInt32Array
var right_queue: PackedInt32Array
var down_queue: PackedInt32Array
var up_queue: PackedInt32Array
var forward_queue: PackedInt32Array
var back_queue: PackedInt32Array
@onready var mesh_instance := $MeshInstance as MeshInstance3D


static func get_x(i: int) -> int:
	return i & MAX


static func get_y(i: int) -> int:
	return (i >> Y_OFFSET) & MAX


static func get_z(i: int) -> int:
	return (i >> Z_OFFSET) & MAX


static func pack_coords(x: int, y: int, z: int) -> int:
	return x | (y << Y_OFFSET) | (z << Z_OFFSET)


static func get_type(voxel: int) -> int:
	return voxel & TYPE_MASK


static func get_red(voxel: int) -> int:
	return (voxel >> RED_OFFSET) & RED_MASK


static func get_green(voxel: int) -> int:
	return (voxel >> GREEN_OFFSET) & GREEN_MASK


static func get_blue(voxel: int) -> int:
	return (voxel >> BLUE_OFFSET) & BLUE_MASK


static func create_voxel(type: int, red: int, green: int, blue: int) -> int:
	return (
			type | (red << RED_OFFSET) | (green << GREEN_OFFSET) |
			(blue << BLUE_OFFSET)
	)


func _init() -> void:
	voxels.resize(VOLUME)
	images.resize(LIGHT_MAP_WIDTH)
	for i in LIGHT_MAP_WIDTH:
		images[i] = Image.create_empty(
				LIGHT_MAP_WIDTH, LIGHT_MAP_WIDTH, false, Image.FORMAT_RGB8
		)
	light_map.create(
			Image.FORMAT_RGB8, LIGHT_MAP_WIDTH, LIGHT_MAP_WIDTH,
			LIGHT_MAP_WIDTH, false, images
	)
	material.set_shader_parameter("lightMap", light_map)


func get_voxel(x: int, y: int, z: int) -> int:
	return voxels[Chunk.pack_coords(x, y, z)]


func set_voxel(x: int, y: int, z: int, voxel: int) -> void:
	voxels[Chunk.pack_coords(x, y, z)] = voxel
