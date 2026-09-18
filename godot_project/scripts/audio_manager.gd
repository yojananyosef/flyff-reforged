extends Node
## Autoload AudioManager: musica de zona en loop, tema de combate tras
## agresion (6 s), stings con reanudacion, SFX polifonico y mute con M.
## Los archivos viven en `res://audio/` (generado por setup_audio.py,
## gitignorado). Sin ellos, todo es no-op con un aviso (juego en silencio).

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const COMBAT_TIMEOUT := 6.0

const MUSIC := {
	"zone_ironhold": "BgmBa3Saintmorning.ogg",
	"combat": "BgmBaCrisis.ogg",
	"sting_quest": "BgmNPCAccomplish.ogg",
	"sting_death": "BgmInDeath.ogg",
}

const SFX := {
	"swing": "NpcComSwing01.wav",
	"hit": "Item1WpnAtk.wav",
	"monster_hurt": "NpcAibattDmg1.wav",
	"monster_die": "NpcAibattDie1.wav",
	"player_hurt": "PcDmgSwdC.wav",
	"level_up": "PcLevelup.wav",
	"quest_accept": "ActionRegister.wav",
	"ui_click": "InfClick.wav",
	"ui_open": "InfOpen.wav",
	"ui_close": "InfClose.wav",
	"pickup": "InfGroundPickup.wav",
	"reward": "ItemDropDing.wav",
	"heal": "ItemGnPotion.wav",
}

var muted := false
var _combat_timer := 0.0
var _in_combat_music := false
var _missing: Array[String] = []

var _music: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _sfx: AudioStreamPlayer


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = _make_player("Music", -10.0)
	_sting = _make_player("Music", -8.0)
	_sfx = _make_player("SFX", -4.0)
	_sfx.max_polyphony = 8
	add_child(_music)
	add_child(_sting)
	add_child(_sfx)
	_sting.finished.connect(_on_sting_finished)
	_check_files()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			toggle_mute()


func _process(delta: float) -> void:
	if _combat_timer > 0.0:
		_combat_timer -= delta
		if _combat_timer <= 0.0 and _in_combat_music:
			_in_combat_music = false
			_play_music_track("zone_ironhold")


func play_zone_music() -> void:
	_in_combat_music = false
	_combat_timer = 0.0
	_play_music_track("zone_ironhold")


func notify_combat() -> void:
	_combat_timer = COMBAT_TIMEOUT
	if not _in_combat_music:
		_in_combat_music = true
		_play_music_track("combat")


func play_sfx(sfx_name: String) -> void:
	if not SFX.has(sfx_name):
		push_warning("[Audio] SFX desconocido: " + sfx_name)
		return
	_play(_sfx, SFX_DIR + str(SFX[sfx_name]))


func play_sting(sting_name: String) -> void:
	if not MUSIC.has(sting_name):
		push_warning("[Audio] sting desconocido: " + sting_name)
		return
	var path: String = MUSIC_DIR + str(MUSIC[sting_name])
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	_music.stream_paused = true
	_sting.stream = stream
	_sting.play()


func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	print("[Audio] mute: %s" % str(muted))


func known_sfx() -> Array:
	return SFX.keys()


func missing_files() -> Array[String]:
	return _missing


func _on_sting_finished() -> void:
	_music.stream_paused = false
	if _music.stream != null and not _music.playing:
		_music.play()


func _play_music_track(track_name: String) -> void:
	_play(_music, MUSIC_DIR + str(MUSIC[track_name]))


func _play(player: AudioStreamPlayer, path: String) -> void:
	if muted:
		return
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	player.stream = stream
	player.play()


func _make_player(bus: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.volume_db = volume_db
	return p


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _check_files() -> void:
	_missing.clear()
	for f in MUSIC.values():
		if not ResourceLoader.exists(MUSIC_DIR + str(f)):
			_missing.append(str(f))
	for f in SFX.values():
		if not ResourceLoader.exists(SFX_DIR + str(f)):
			_missing.append(str(f))
	if not _missing.is_empty():
		push_warning("[Audio] sin archivos (%d): ejecuta setup_audio.py. Juego en silencio." % _missing.size())
	else:
		print("[Audio] 16/16 archivos presentes")
