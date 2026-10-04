extends SceneTree
## assets/fonts/src の PixelMplus10 から、ドット絵用の設定を焼き込んだフォントを作る。
## 10px固定で描き、大きい文字は整数倍に拡大する(崩れないため)。
## 実行: Godot --headless --path . -s tools/make_font.gd

const SOURCE := "res://assets/fonts/src/PixelMplus10-Regular.ttf"
const OUTPUT := "res://assets/fonts/pixel_mplus10.res"
const FIXED_SIZE := 10


func _init() -> void:
	var font := FontFile.new()
	font.load_dynamic_font(SOURCE)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.allow_system_fallback = false
	font.fixed_size = FIXED_SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var err := ResourceSaver.save(font, OUTPUT)
	print("saved %s: %s" % [OUTPUT, error_string(err)])
	for size in [8, 10, 12, 16, 32]:
		print(
			size, " -> ", load(OUTPUT).get_string_size("居合あA", HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		)
	quit()
