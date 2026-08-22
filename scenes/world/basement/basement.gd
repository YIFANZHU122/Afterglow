extends WorldSceneController

## 地下室场景（1280×720）
## 场景加载时定位玩家出生点，并设置相机边界（由场景尺寸决定，而非硬编码在玩家场景中）

func _get_world_size() -> Vector2:
	return Vector2(1280.0, 720.0)
