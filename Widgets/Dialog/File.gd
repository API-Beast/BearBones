extends FileDialog

func on_display_dialog():
	if not current_file:
		self.current_dir = Session.recover("file_dialog_current_dir", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS ))

func on_dialog_closed():
	Session.store("file_dialog_current_dir", self.current_dir)