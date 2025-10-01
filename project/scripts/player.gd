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

class_name Player
extends Node3D


const MIN_YAW := -PI
const MAX_YAW := PI
const MIN_PITCH := -PI * 0.5
const MAX_PITCH := PI * 0.5

@export var view_distance := 70.0
@export var _movement_speed := 20.0
@export var _rotation_speed := 4.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var width := get_viewport().get_visible_rect().size.x as float
		rotation.y = wrapf(
				rotation.y - motion.relative.x * _rotation_speed / width,
				MIN_YAW, MAX_YAW
		)
		rotation.x = clampf(
				rotation.x - motion.relative.y * _rotation_speed / width,
				MIN_PITCH, MAX_PITCH
		)


func _process(delta: float) -> void:
	var movement_input := Vector3(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_down", "move_up"),
			Input.get_axis("move_forward", "move_back")
	)
	if movement_input.length_squared() > 1.0:
		movement_input = movement_input.normalized()
	translate(movement_input * _movement_speed * delta)

	var rotation_input := Input.get_vector(
			"rotate_left", "rotate_right", "rotate_down", "rotate_up"
	)
	rotation.y = wrapf(
			rotation.y - rotation_input.x * _rotation_speed * delta,
			MIN_YAW, MAX_YAW
	)
	rotation.x = clampf(
			rotation.x + rotation_input.y * _rotation_speed * delta,
			MIN_PITCH, MAX_PITCH
	)
