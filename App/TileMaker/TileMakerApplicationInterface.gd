class_name TileMakerApplicationInterface
extends ApplicationInterface

var workspace_view = null

func _init():
	workspace_view = preload("res://App/TileMaker/Views/BuildTileView.tscn").instance()

func get_view_for_context(context):
	return workspace_view