extends WorldSceneController

## 慈航郊外场景（3840×2160，为 1280×720 的 3 倍）
## 场景加载时定位玩家出生点，并设置相机边界（由场景尺寸决定，而非硬编码在玩家场景中）

func _get_world_size() -> Vector2:
	return Vector2(3840.0, 2160.0)
