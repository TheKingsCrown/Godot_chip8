extends Node2D

# This PPU (Picture Proccessing Unit) works by utilizing the set_pixel() method of the Image class
# and setting that as the texture of a Sprite2D Node.

# initializes the screen_output (just a Sprite2D Node) and the Image buffer using the Image class
@onready var screen_output: Sprite2D = $ScreenOutput
@onready var image_buffer = Image.create(SCREEN_WIDTH, SCREEN_HEIGHT, false, Image.FORMAT_RGB8)

# Holds the screen width and height.
# I need to see if there's a way to get the width and height from the project settings.
const SCREEN_WIDTH: int = 64
const SCREEN_HEIGHT: int = 32

# Stores the colors for an off/on pixel
const PIXEL_OFF: Color = Color.DIM_GRAY
const PIXEL_ON: Color = Color.GAINSBORO

# Sets all pixels on the screen to black, otherwise we'd get the default Godot background color.
func initialize() -> void:
	for x in range(SCREEN_WIDTH):
		for y in range(SCREEN_HEIGHT):
			image_buffer.set_pixel(x, y, PIXEL_OFF)
	draw_buffer()

# changes the pixel, turning it off if it was on and on if it was off. 
func change_pixel(x: int, y: int) -> bool:
	x -= 1
	y -= 1
	match image_buffer.get_pixel(x, y):
		PIXEL_OFF:
			image_buffer.set_pixel(x, y, PIXEL_ON)
		PIXEL_ON:
			image_buffer.set_pixel(x, y, PIXEL_OFF)
			return true
	return false

# Draws to the screen from the image buffer.
func draw_buffer() -> void:
	var image_texture = ImageTexture.create_from_image(image_buffer)
	screen_output.texture = image_texture

#clears the screen
func clear_screen() -> void:
	image_buffer.fill(PIXEL_OFF)
	draw_buffer()
