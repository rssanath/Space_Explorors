class_name LaunchAudio
extends RefCounted

## LaunchAudio.gd - Procedural Aerospace Audio Synthesizer for MARS DEEP
## Generates clean procedural sound effects for countdown, ignition, rumble, clamp release, radio chatter, and thrusters in memory.

static func create_beep(freq: float = 880.0, duration: float = 0.12, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		# Sine wave with smooth envelope
		var envelope := 1.0
		var ramp := float(sample_rate) * 0.015 # 15ms ramp
		if i < ramp:
			envelope = float(i) / ramp
		elif i > num_samples - ramp:
			envelope = float(num_samples - i) / ramp
			
		var sample_val := sin(TAU * freq * t) * envelope * 0.75
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

static func create_engine_rumble(duration: float = 2.0, sample_rate: int = 22050) -> AudioStreamWAV:
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var last_noise := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		# Deep filtered brown noise mixed with 45Hz sub-bass tone
		var raw := (randf() * 2.0 - 1.0)
		last_noise = (last_noise * 0.92) + (raw * 0.08)
		var sub_bass := sin(TAU * 45.0 * t) * 0.35 + sin(TAU * 85.0 * t) * 0.25
		
		# Smooth looping boundary
		var env := 1.0
		var boundary := 500
		if i < boundary:
			env = float(i) / float(boundary)
		elif i > num_samples - boundary:
			env = float(num_samples - i) / float(boundary)
			
		var sample_val := (last_noise * 0.65 + sub_bass) * env
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 500
	stream.loop_end = num_samples - 500
	stream.data = byte_data
	return stream

static func create_clamp_clank(sample_rate: int = 22050) -> AudioStreamWAV:
	var duration := 0.4
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var decay := exp(-t * 18.0)
		var metallic := sin(TAU * 340.0 * t) * 0.5 + sin(TAU * 820.0 * t) * 0.35 + sin(TAU * 1250.0 * t) * 0.2
		var impact := (randf() * 2.0 - 1.0) * exp(-t * 60.0)
		var sample_val := (metallic * 0.6 + impact * 0.4) * decay
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

static func create_ignition_burst(sample_rate: int = 22050) -> AudioStreamWAV:
	var duration := 1.2
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var filter := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var raw := (randf() * 2.0 - 1.0)
		var cutoff := clampf(t * 1.5, 0.05, 0.4)
		filter = filter * (1.0 - cutoff) + raw * cutoff
		var env := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var sample_val := filter * env * 1.2
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

static func create_radio_chatter(sample_rate: int = 22050) -> AudioStreamWAV:
	# Short radio transmission burst with quindar beep and squelch
	var duration := 0.28
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var beep := sin(TAU * 2524.0 * t) * 0.35 if t < 0.1 else sin(TAU * 2475.0 * t) * 0.3
		var squelch := (randf() * 2.0 - 1.0) * 0.14 if t >= 0.08 else 0.0
		var env := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var sample_val := (beep + squelch) * env
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

static func create_rcs_burst(sample_rate: int = 22050) -> AudioStreamWAV:
	# Short cold-gas thruster hiss
	var duration := 0.16
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var filter := 0.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var raw := (randf() * 2.0 - 1.0)
		filter = filter * 0.75 + raw * 0.25
		var env := exp(-t * 20.0)
		var sample_val := filter * env * 0.8
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

static func create_alarm_beep(sample_rate: int = 22050) -> AudioStreamWAV:
	# Dual-frequency warning chime
	var duration := 0.22
	var num_samples := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var tone := sin(TAU * 784.0 * t) * 0.5 + sin(TAU * 1046.5 * t) * 0.35
		var env := sin(clampf(t / duration, 0.0, 1.0) * PI)
		var sample_val := tone * env * 0.65
		var sample_int := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_int)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream
