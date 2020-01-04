extends Node

func _init():
	Serializer.register_type("UndoStack", UndoStack)
	Serializer.register_type("UndoStack.ChangeCollection", UndoStack.ChangeCollection)
	Serializer.register_type("UndoStack.ItemStateChange", UndoStack.ItemStateChange)
	
	Serializer.register_type("ShardList", ShardList)
	Serializer.register_type("InputTrigger", InputTrigger)
