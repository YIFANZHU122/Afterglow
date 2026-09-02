extends RefCounted
class_name AccessibilitySettingsModel

const FORMAT_VERSION: int = 1

var _text_scale: float = 1.0
var _color_redundancy: bool = true
var _flash_intensity: float = 1.0
var _screen_shake_intensity: float = 1.0


func set_text_scale(value: float) -> bool:
	if not is_finite(value) or value < 0.75 or value > 2.0:
		return false
	_text_scale = value
	return true


func set_color_redundancy(enabled: bool) -> bool:
	_color_redundancy = enabled
	return true


func set_flash_intensity(value: float) -> bool:
	if not is_finite(value) or value < 0.0 or value > 1.0:
		return false
	_flash_intensity = value
	return true


func set_screen_shake_intensity(value: float) -> bool:
	if not is_finite(value) or value < 0.0 or value > 1.0:
		return false
	_screen_shake_intensity = value
	return true


func create_snapshot() -> Dictionary:
	return {"format_version": FORMAT_VERSION, "text_scale": _text_scale, "color_redundancy": _color_redundancy, "flash_intensity": _flash_intensity, "screen_shake_intensity": _screen_shake_intensity}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != FORMAT_VERSION:
		return false
	if not set_text_scale(float(snapshot.get("text_scale", -1.0))):
		return false
	if not set_flash_intensity(float(snapshot.get("flash_intensity", -1.0))):
		return false
	if not set_screen_shake_intensity(float(snapshot.get("screen_shake_intensity", -1.0))):
		return false
	if snapshot.get("color_redundancy") is not bool:
		return false
	_color_redundancy = bool(snapshot["color_redundancy"])
	return true
