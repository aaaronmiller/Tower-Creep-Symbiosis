extends SceneTree

func _init():
	var strategy_diversity = 0.7
	var player_retention = 0.6
	var asset_variety = 0.5
	var b_state = 0.4 * strategy_diversity + 0.4 * player_retention + 0.2 * asset_variety
	print("B(state) = ", b_state)
	quit()
