extends Node
## Áudio (Autoload "AudioManager").
## Todos os sons e a música são sintetizados por código quando o jogo
## abre: não há arquivos externos, então não há licença de terceiros
## nem aumento no tamanho do app. Para usar arquivos .ogg/.wav no futuro,
## basta trocar o stream em _sfx["nome"] ou em _music.stream.

const MIX_RATE := 22050
const SFX_VOICES := 6
const MUSIC_VOLUME_DB := -10.0

var _sfx := {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music: AudioStreamPlayer
var _music_thread: Thread
var _wants_music := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	_build_sfx()
	_music_thread = Thread.new()
	_music_thread.start(_build_music)
	SaveManager.settings_changed.connect(_apply_settings)


func _process(_delta: float) -> void:
	if _music_thread != null and not _music_thread.is_alive():
		_music.stream = _music_thread.wait_to_finish()
		_music_thread = null
		_apply_settings()


func _exit_tree() -> void:
	if _music_thread != null:
		_music_thread.wait_to_finish()


func play_music() -> void:
	_wants_music = true
	_apply_settings()


func play_sfx(sound: String, pitch_variation := 0.0) -> void:
	if not SaveManager.get_setting("sfx") or not _sfx.has(sound):
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = _sfx[sound]
	p.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	p.play()


func set_ducked(value: bool) -> void:
	_music.volume_db = MUSIC_VOLUME_DB - (18.0 if value else 0.0)


func _apply_settings() -> void:
	var on := _wants_music and SaveManager.get_setting("music") and _music.stream != null
	if on and not _music.playing:
		_music.play()
	elif not on and _music.playing:
		_music.stop()


# --------------------------------------------------------------- Síntese

func _build_sfx() -> void:
	_sfx["coin"] = _to_stream(_concat([
		_tone(0.06, 988.0, 988.0, "square", 0.16),
		_tone(0.16, 1319.0, 1319.0, "square", 0.16),
	]))
	_sfx["jump"] = _to_stream(_tone(0.2, 300.0, 760.0, "triangle", 0.5))
	_sfx["slide"] = _to_stream(_tone(0.28, 0.0, 0.0, "noise", 0.35, 0.08))
	_sfx["bump"] = _to_stream(_mix(_tone(0.14, 180.0, 90.0, "sine", 0.7), _tone(0.1, 0.0, 0.0, "noise", 0.2, 0.2)))
	_sfx["crash"] = _to_stream(_mix(_tone(0.55, 0.0, 0.0, "noise", 0.55, 0.12), _tone(0.5, 120.0, 40.0, "sine", 0.7)))
	_sfx["hop"] = _to_stream(_tone(0.09, 420.0, 820.0, "triangle", 0.35))
	_sfx["splash"] = _to_stream(_mix(_tone(0.5, 0.0, 0.0, "noise", 0.45, 0.06), _tone(0.25, 300.0, 120.0, "sine", 0.4)))
	_sfx["bell"] = _to_stream(_concat([
		_tone(0.18, 1175.0, 1175.0, "triangle", 0.35),
		_tone(0.18, 988.0, 988.0, "triangle", 0.35),
		_tone(0.18, 1175.0, 1175.0, "triangle", 0.35),
		_tone(0.18, 988.0, 988.0, "triangle", 0.35),
	]))
	_sfx["cloud"] = _to_stream(_mix(_tone(0.7, 0.0, 0.0, "noise", 0.35, 0.03), _tone(0.6, 520.0, 260.0, "sine", 0.25)))
	_sfx["click"] = _to_stream(_tone(0.05, 880.0, 880.0, "sine", 0.35))
	_sfx["beep"] = _to_stream(_tone(0.12, 660.0, 660.0, "triangle", 0.45))
	_sfx["go"] = _to_stream(_tone(0.25, 990.0, 990.0, "triangle", 0.45))
	_sfx["reward"] = _to_stream(_concat([
		_tone(0.08, 1047.0, 1047.0, "triangle", 0.4),
		_tone(0.08, 1319.0, 1319.0, "triangle", 0.4),
		_tone(0.08, 1568.0, 1568.0, "triangle", 0.4),
		_tone(0.22, 2093.0, 2093.0, "triangle", 0.4),
	]))


func _tone(duration: float, f0: float, f1: float, wave: String, volume: float, lowpass := 1.0) -> PackedFloat32Array:
	var n := int(duration * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var filtered := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = n
	for i in n:
		var t := float(i) / n
		var freq := lerpf(f0, f1, t)
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var v := 0.0
		match wave:
			"sine":
				v = sin(TAU * phase)
			"square":
				v = 1.0 if phase < 0.5 else -1.0
			"triangle":
				v = 4.0 * absf(phase - 0.5) - 1.0
			_:
				v = rng.randf_range(-1.0, 1.0)
		filtered += (v - filtered) * lowpass
		var env := minf(float(i) / (0.005 * MIX_RATE), 1.0) * pow(1.0 - t, 2.0)
		out[i] = filtered * env * volume
	return out


func _concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate()
	if b.size() > out.size():
		out.resize(b.size())
	for i in b.size():
		out[i] += b[i]
	return out


func _to_stream(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


## Música alegre em loop (Dó - Lá menor - Fá - Sol), gerada em thread
## separada para não atrasar a abertura do jogo.
func _build_music() -> AudioStreamWAV:
	var bpm := 112.0
	var beat := 60.0 / bpm
	var bars := 8
	var total := int(bars * 4 * beat * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var chords := [
		[48, [72, 76, 79, 84]],
		[45, [69, 72, 76, 81]],
		[41, [65, 69, 72, 77]],
		[43, [67, 71, 74, 79]],
	]
	var pattern_a := [0, 1, 2, 3, 2, 1, 0, 1]
	var pattern_b := [3, 2, 1, 2, 0, 2, 1, 3]
	var eighth := beat * 0.5
	for bar in bars:
		var chord: Array = chords[bar % 4]
		var bar_start := bar * 4 * beat
		var pattern: Array = pattern_a if bar < 4 else pattern_b
		for e in 8:
			var t0 := bar_start + e * eighth
			var bass_note: int = chord[0] + (12 if e % 2 == 1 else 0)
			_add_note(buf, t0, eighth * 0.9, _midi(bass_note), "triangle", 0.22)
			var lead_note: int = chord[1][pattern[e]]
			_add_note(buf, t0, eighth * 0.8, _midi(lead_note), "square", 0.06)
			if e % 2 == 1:
				_add_noise(buf, t0, 0.03, 0.05)
		for b in 4:
			var tb := bar_start + b * beat
			if b % 2 == 0:
				_add_kick(buf, tb)
			else:
				_add_noise(buf, tb, 0.12, 0.12)
	return _to_stream(buf, true)


func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _add_note(buf: PackedFloat32Array, start: float, duration: float, freq: float, wave: String, volume: float) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(duration * MIX_RATE)
	var phase := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			return
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var v: float
		if wave == "square":
			v = 1.0 if phase < 0.5 else -1.0
		else:
			v = 4.0 * absf(phase - 0.5) - 1.0
		var t := float(i) / n
		var env := minf(float(i) / 80.0, 1.0) * (1.0 - t)
		buf[idx] += v * env * volume


func _add_noise(buf: PackedFloat32Array, start: float, duration: float, volume: float) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(duration * MIX_RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = i0
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			return
		var t := float(i) / n
		buf[idx] += rng.randf_range(-1.0, 1.0) * pow(1.0 - t, 3.0) * volume


func _add_kick(buf: PackedFloat32Array, start: float) -> void:
	var i0 := int(start * MIX_RATE)
	var n := int(0.16 * MIX_RATE)
	var phase := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= buf.size():
			return
		var t := float(i) / n
		phase += lerpf(130.0, 45.0, t) / MIX_RATE
		buf[idx] += sin(TAU * phase) * pow(1.0 - t, 2.0) * 0.45
