extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): a rendered reel's video in a Short. A video reel plays its Theora file under
## the live captions (its picture: ShortPlayer's plate) on the Short's clock; a `video` actor plays a clip in a scene. On
## the web the videos come later (the reels pack): until then the reel's still and "coming…" show and it does not play.

const REEL := "saturn_up_close"

var _nodes: Array[Node] = []


func after_each() -> void:
	ReelPack.exists_check = Callable()
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	ShortLibrary.clear_cache()


func _player(s: Dictionary) -> ShortPlayer:
	var p := ShortPlayer.new()
	p.voice_on = false
	p.size = Vector2(288, 512)
	add_child(p)
	_nodes.append(p)
	p.build(s)
	return p


func test_a_video_reel_plays_its_video_under_the_captions() -> void:
	var p := _player(ShortLibrary.get_short(REEL))
	var view := p.plate() as VideoView
	assert_not_null(view, "a video reel's picture is its video (the live stage stays for the studio)")
	assert_true(view.can_play())
	p.play()
	assert_true(p.playing)
	assert_not_null(view.video.stream, "playing opens the video")
	assert_almost_eq(view.video.get_stream_length(), p.length(), 0.2, "the video is as long as the Short")
	for i in 20:
		p.advance(1.0 / 30.0)
		await get_tree().process_frame
	assert_true(view.video.is_playing())
	assert_false(view.video.paused)
	assert_almost_eq(view.video.stream_position, p.time, VideoView.DRIFT + 0.05, "in step with the Short")


func test_a_neighbour_shows_its_still_and_opens_nothing() -> void:
	var p := _player(ShortLibrary.get_short(REEL))
	var view := p.plate() as VideoView
	p.seek(12.5)
	assert_null(view.video.stream, "a poster in the feed decodes nothing (a seek cost tens of ms)")
	assert_false(view.shows_video())
	assert_not_null(view._still.texture)
	p.play()
	assert_true(view.shows_video(), "it plays: the video opens")


func test_a_paused_seek_shows_the_exact_moment() -> void:
	var p := _player(ShortLibrary.get_short(REEL))
	var view := p.plate() as VideoView
	view.exact = true   # the studio's frame sheets
	p.seek(12.5)
	await get_tree().process_frame
	assert_true(view.video.paused, "paused: the frame holds")
	assert_almost_eq(view.video.stream_position, 12.5, 0.06)
	p.seek(3.0)
	assert_almost_eq(view.video.stream_position, 3.0, 0.06, "back again")


func test_until_the_video_is_here_the_reel_shows_its_still_and_waits() -> void:
	ReelPack.exists_check = func(_path: String) -> bool: return false
	var p := _player(ShortLibrary.get_short(REEL))
	var view := p.plate() as VideoView
	assert_false(view.can_play())
	assert_false(p.can_play())
	assert_not_null(view._still.texture, "its still")
	assert_true(view._coming.visible, "and 'coming…'")
	p.play()
	assert_false(p.playing, "a video reel waits for its video")
	ReelPack.exists_check = func(_path: String) -> bool: return true
	ReelPack.on_pack_loaded("music")
	assert_false(view.can_play(), "another pack changes nothing")
	ReelPack.on_pack_loaded(ReelPack.PACK)
	assert_true(view.can_play(), "the reels pack: it looks again")
	assert_false(view._coming.visible)
	p.play()
	assert_true(p.playing)


func test_a_video_actor_plays_a_clip_in_a_scene() -> void:
	var s := {"id": "clip_test", "title": "A clip", "topic": "space", "link": {"star_map": true}, "scenes": []}
	for i in 3:
		s.scenes.append({"seconds": 8, "background": "space", "caption": "Look.", "say": "Look at it.", "actors": [
			{"kind": "video", "file": REEL, "start": 20.0, "at": [180, 200], "w": 180, "h": 320}]})
	s.scenes[2].caption = "What do you see?"
	assert_eq(ShortCheck.problems(s), [] as Array[String])
	var p := _player(s)
	var actor: ShortActor = p.actors_of(1)[0]
	var view := VideoDrawer.view_of(actor)
	assert_not_null(view)
	assert_eq(actor.size, Vector2(180, 320))
	view.exact = true
	p.seek(8.0 + 2.0)
	await get_tree().process_frame
	assert_almost_eq(view.video.stream_position, 22.0, 0.06, "the scene's time plus its start")


func test_the_studio_films_the_live_stage_of_a_video_reel() -> void:
	var p := ShortPlayer.new()
	p.prefer_live = true
	p.size = Vector2(288, 512)
	add_child(p)
	_nodes.append(p)
	p.build(ShortLibrary.get_short(REEL))
	assert_true(p.plate() is Scene3DView, "the studio and the renderer draw its stage")
