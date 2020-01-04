extends ViewInterface

func build_context(document):
	return DocumentContext.new(document)

func build_ui(new_context):
	pass

func get_tab_name(context):
	return context.doc.get_name()