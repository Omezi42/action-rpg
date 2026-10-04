extends SceneTree
## unityroom のサムネイル用の一枚絵アニメ(144x144 のコマを build/promo/icon_frames/ に撮る)。ウィンドウありで起動する。
## 月下で溜める侍 → 白い閃光で一直線に斬り抜け → 納刀の瞬間に鬼が斜めに割れる → 暗転して最初へ。題字は常に出す。
## GIFにするのは tools/make_promo_gif.py。実行: Godot --path . --script res://tools/promo_icon.gd

const FRAMES_DIR := "res://build/promo/icon_frames"
const SIZE := Vector2i(144, 144)
const FRAME_COUNT := 64


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_DIR))
	for file in DirAccess.get_files_at(FRAMES_DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FRAMES_DIR.path_join(file)))
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)
	var art := IconArt.new()
	viewport.add_child(art)
	root.add_child(viewport)
	for f in FRAME_COUNT:
		art.frame = f
		art.queue_redraw()
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(FRAMES_DIR.path_join("%04d.png" % f))
	print("icon frames: %d" % FRAME_COUNT)
	quit()


class IconArt:
	extends Node2D

	const CHARGE_END := 20
	const STRIKE := 21
	const SHEATHE := 30
	const SPLIT_TIME := 10
	const FADE_OUT := 56
	const FADE_IN := 4
	const LAST := 63
	const CANVAS := Vector2(144, 144)

	const SKY_TOP := Color("0b0f1c")
	const SKY_BOTTOM := Color("2a2440")
	const SKY_BANDS := 8
	const MOON := Color("efe3c4")
	const MOON_HALO := Color(0.94, 0.89, 0.77, 0.12)
	const MOON_CENTER := Vector2(104, 30)
	const MOON_RADIUS := 21.0
	const GROUND := Color("07080d")
	const GROUND_TOP := 86
	const ONI_BODY := Color("140d14")
	const ONI_RIM := Color("5b2a3a")
	const ONI_EYE := Color("ff3b3b")
	const ONI_FEET: Array[Vector2] = [Vector2(58, 86), Vector2(78, 86), Vector2(98, 86)]
	const KIMONO := Color("2b3a67")
	const KIMONO_DARK := Color("1a2342")
	const SKIN := Color("f2d0a4")
	const HAIR := Color("101010")
	const SASH := Color("b8323a")
	const BLADE := Color("f4f9ff")
	const GOLD := Color("ffd84a")
	const SAMURAI_START := Vector2(24, 86)
	const SAMURAI_END := Vector2(126, 86)
	const STRIKE_Y := 76.0
	const BLOOD := Color("d8323a")
	const TITLE_BIG := "居合"
	const TITLE_SMALL := "サバイバー"
	const TITLE_BIG_SIZE := 40
	const TITLE_SMALL_SIZE := 10
	const TITLE_POS := Vector2(6, 136)
	const TITLE_COLOR := Color("f4f1e8")
	const OUTLINE := Color("05060a")
	const HITOKIRI := "三人斬り"
	const HITOKIRI_POS := Vector2(6, 16)

	var frame := 0
	var _font: Font = ThemeDB.fallback_font

	func _ready() -> void:
		_font = load(ProjectSettings.get_setting("gui/theme/custom_font"))

	func _draw() -> void:
		_draw_sky()
		_draw_oni_all()
		_draw_ground()
		_draw_samurai()
		_draw_strike()
		_draw_fade()
		_draw_title()
		if frame == STRIKE - 1:
			draw_rect(Rect2(Vector2.ZERO, CANVAS), Color.WHITE)

	func _draw_sky() -> void:
		var band := CANVAS.y / SKY_BANDS
		for i in SKY_BANDS:
			var color := SKY_TOP.lerp(SKY_BOTTOM, float(i) / (SKY_BANDS - 1))
			draw_rect(Rect2(0, floorf(i * band), CANVAS.x, ceilf(band) + 1), color)
		draw_circle(MOON_CENTER, MOON_RADIUS + 6, MOON_HALO)
		draw_circle(MOON_CENTER, MOON_RADIUS + 3, MOON_HALO)
		draw_circle(MOON_CENTER, MOON_RADIUS, MOON)
		draw_circle(MOON_CENTER + Vector2(-7, 5), 4, Color(MOON.darkened(0.08)))
		draw_circle(MOON_CENTER + Vector2(6, -6), 2.5, Color(MOON.darkened(0.06)))

	func _draw_ground() -> void:
		draw_rect(Rect2(0, GROUND_TOP, CANVAS.x, CANVAS.y - GROUND_TOP), GROUND)
		for x in range(0, CANVAS.x, 6):
			draw_rect(Rect2(x, GROUND_TOP - 2 - (x * 7 % 3), 1, 2 + (x * 7 % 3)), GROUND)

	func _draw_oni_all() -> void:
		if frame >= SHEATHE + SPLIT_TIME:
			return
		var split := (
			clampf(float(frame - SHEATHE) / SPLIT_TIME, 0.0, 1.0) if frame >= SHEATHE else 0.0
		)
		for i in ONI_FEET.size():
			var bob := 0.0 if frame >= STRIKE else float((frame / 4 + i) % 2)
			_draw_oni(ONI_FEET[i] + Vector2(0, -bob), split, i)

	## 鬼の影絵。split が進むと斜めの切り口から上半分がずれ、薄れて消える
	func _draw_oni(feet: Vector2, split: float, index: int) -> void:
		var fade := 1.0 - split
		var top_shift := Vector2(5, -4) * split
		var cut_dir := (
			Vector2(1, -0.6).normalized() if index % 2 == 0 else Vector2(1, 0.5).normalized()
		)
		var cut_center := feet + Vector2(0, -13)
		var body := PackedVector2Array(
			[
				feet + Vector2(-8, 0),
				feet + Vector2(-9, -16),
				feet + Vector2(9, -16),
				feet + Vector2(8, 0)
			]
		)
		var head_center := feet + Vector2(0, -21)
		for half in 2:
			var shift := top_shift if half == 0 else Vector2.ZERO
			var color := Color(ONI_BODY, fade)
			var clip := _half_plane(cut_center, cut_dir, half == 0)
			_draw_clipped(body, clip, shift, color)
			_draw_clipped(_circle_points(head_center, 7.0), clip, shift, color)
			if half == 0:
				_draw_clipped(
					PackedVector2Array(
						[
							head_center + Vector2(-6, -4),
							head_center + Vector2(-8, -12),
							head_center + Vector2(-2, -6)
						]
					),
					clip,
					shift,
					color
				)
				_draw_clipped(
					PackedVector2Array(
						[
							head_center + Vector2(6, -4),
							head_center + Vector2(8, -12),
							head_center + Vector2(2, -6)
						]
					),
					clip,
					shift,
					color
				)
				draw_rect(
					Rect2(head_center + shift + Vector2(-4, -1), Vector2(2, 2)),
					Color(ONI_EYE, fade)
				)
				draw_rect(
					Rect2(head_center + shift + Vector2(2, -1), Vector2(2, 2)), Color(ONI_EYE, fade)
				)
			draw_line(
				feet + shift + Vector2(-9, -16),
				feet + shift + Vector2(-8, 0),
				Color(ONI_RIM, fade),
				1
			)
		if frame >= SHEATHE and frame < SHEATHE + 3:
			var reach := cut_dir * 16.0
			draw_line(cut_center - reach, cut_center + reach, BLADE, 2)
			draw_line(cut_center - reach * 1.4, cut_center + reach * 1.4, Color(BLADE, 0.5), 1)
		if frame >= SHEATHE and frame < SHEATHE + 6:
			for k in 5:
				var angle := TAU * (k + index * 0.37) / 5.0
				var dist := 4.0 + (frame - SHEATHE) * 3.0
				draw_rect(
					Rect2(cut_center + Vector2.from_angle(angle) * dist, Vector2(2, 2)), BLOOD
				)

	func _half_plane(center: Vector2, dir: Vector2, upper: bool) -> PackedVector2Array:
		var normal := Vector2(dir.y, -dir.x) if upper else Vector2(-dir.y, dir.x)
		var far := 200.0
		return PackedVector2Array(
			[
				center - dir * far,
				center + dir * far,
				center + dir * far + normal * far,
				center - dir * far + normal * far,
			]
		)

	func _draw_clipped(
		shape: PackedVector2Array, clip: PackedVector2Array, shift: Vector2, color: Color
	) -> void:
		for part in Geometry2D.intersect_polygons(shape, clip):
			var moved := PackedVector2Array()
			for p in part:
				moved.append((p + shift).round())
			draw_colored_polygon(moved, color)

	func _circle_points(center: Vector2, radius: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in 16:
			points.append(center + Vector2.from_angle(TAU * i / 16.0) * radius)
		return points

	func _draw_samurai() -> void:
		if frame < STRIKE:
			_draw_samurai_at(SAMURAI_START, true, false)
			return
		if frame < STRIKE + 6:
			for k in 3:
				var t := float(k + 1) / 4.0
				var ghost := Color(1, 1, 1, 0.25 * (1.0 - float(frame - STRIKE) / 6.0))
				_draw_ghost(SAMURAI_START.lerp(SAMURAI_END, t), ghost)
		_draw_samurai_at(SAMURAI_END, false, frame < SHEATHE)

	## 侍の姿(足元が原点・右向き)。溜め中は腰を落として柄が光り、抜いた後は刀を後ろへ払う
	func _draw_samurai_at(feet: Vector2, charging: bool, drawn: bool) -> void:
		var squat := 3.0 if charging else 0.0
		var body := Rect2(feet + Vector2(-7, -16 + squat), Vector2(14, 16 - squat))
		draw_rect(body, KIMONO)
		draw_rect(Rect2(body.position + Vector2(0, body.size.y - 4), Vector2(14, 4)), KIMONO_DARK)
		draw_rect(Rect2(feet + Vector2(-7, -9 + squat), Vector2(14, 2)), SASH)
		var head := feet + Vector2(1, -23 + squat)
		draw_circle(head, 7, SKIN)
		draw_rect(Rect2(head + Vector2(-7, -7), Vector2(14, 5)), HAIR)
		draw_rect(Rect2(head + Vector2(-9, -5), Vector2(4, 4)), HAIR)
		draw_rect(Rect2(head + Vector2(3, 0), Vector2(2, 2)), HAIR)
		var hilt := feet + Vector2(6, -10 + squat)
		if drawn:
			draw_line(hilt, hilt + Vector2(-22, 6), BLADE, 2)
			draw_line(hilt + Vector2(-22, 6), hilt + Vector2(-25, 7), Color(BLADE, 0.6), 1)
		else:
			draw_line(hilt, hilt + Vector2(5, -4), HAIR, 2)
			draw_line(hilt + Vector2(-2, 1), hilt + Vector2(-16, 4), HAIR, 2)
		if charging and frame >= CHARGE_END - 8:
			var pulse := 0.5 + 0.5 * float(frame % 2)
			draw_circle(hilt, 4.0 + pulse * 2.0, Color(GOLD, 0.35 + 0.4 * pulse))
		if charging:
			_draw_guide(feet)

	func _draw_ghost(feet: Vector2, color: Color) -> void:
		draw_rect(Rect2(feet + Vector2(-7, -16), Vector2(14, 16)), color)
		draw_circle(feet + Vector2(1, -23), 7, color)

	## 踏み込みの予告線(点線)。溜めの終わりは一閃の金色
	func _draw_guide(feet: Vector2) -> void:
		var color := GOLD if frame >= CHARGE_END - 8 else Color(1, 1, 1, 0.5)
		var y := STRIKE_Y + 6
		for x in range(int(feet.x) + 10, int(SAMURAI_END.x), 6):
			draw_rect(Rect2(x, y, 3, 1), color)

	## 斬り抜けた線の白い光。太い帯から細く消えていく
	func _draw_strike() -> void:
		if frame < STRIKE or frame >= SHEATHE:
			return
		var t := float(frame - STRIKE) / (SHEATHE - STRIKE)
		var width := lerpf(7.0, 1.0, t)
		var from := Vector2(SAMURAI_START.x - 4, STRIKE_Y)
		var to := Vector2(SAMURAI_END.x - 6, STRIKE_Y)
		draw_line(from, to, Color(GOLD, 0.5 * (1.0 - t)), width + 4)
		draw_line(from, to, Color(BLADE, 1.0 - t * 0.6), width)

	func _draw_fade() -> void:
		var alpha := 0.0
		if frame >= FADE_OUT:
			alpha = float(frame - FADE_OUT + 1) / (LAST - FADE_OUT + 1)
		elif frame < FADE_IN:
			alpha = 1.0 - float(frame + 1) / (FADE_IN + 1)
		if alpha > 0.0:
			draw_rect(Rect2(0, 0, CANVAS.x, GROUND_TOP), Color(0, 0, 0, alpha))

	func _draw_title() -> void:
		var flash := frame == STRIKE or frame == SHEATHE
		var color := GOLD if flash else TITLE_COLOR
		var shake := Vector2(1, 0) if frame == SHEATHE else Vector2.ZERO
		_outlined(TITLE_BIG, TITLE_POS + shake, TITLE_BIG_SIZE, color)
		var big_width := (
			_font.get_string_size(TITLE_BIG, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_BIG_SIZE).x
		)
		var small_pos := TITLE_POS + Vector2(big_width + 4, 0) + shake
		_outlined(TITLE_SMALL, small_pos, TITLE_SMALL_SIZE, TITLE_COLOR)
		draw_rect(
			Rect2(
				small_pos + Vector2(0, 3),
				Vector2(
					(
						_font
						. get_string_size(
							TITLE_SMALL, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SMALL_SIZE
						)
						. x
					),
					2
				)
			),
			SASH
		)
		if frame >= SHEATHE and frame < FADE_OUT:
			_outlined(HITOKIRI, HITOKIRI_POS, 10, GOLD)

	func _outlined(text: String, pos: Vector2, size: int, color: Color) -> void:
		for offset: Vector2 in [
			Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)
		]:
			draw_string(
				_font,
				pos + offset * (size / 10),
				text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				size,
				OUTLINE
			)
		draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
