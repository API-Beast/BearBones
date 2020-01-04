extends Node

var threads = []
var errors = []

var num_tasks = 0
var tasks = {}
var task_id = 0

signal task_status_changed()
signal all_tasks_finished()

func task_started(descr):
	# Clear errors if blank slate
	if num_tasks == 0:
		errors = []

	num_tasks += 1
	task_id += 1
	tasks[task_id] = descr
	emit_signal("task_status_changed")
	return task_id

func task_ended(task_id):
	num_tasks -= 1
	tasks.erase(task_id)
	emit_signal("task_status_changed")
	if num_tasks == 0:
		emit_signal("all_tasks_finished")

func task_error(descr):
	errors.push_back(descr)
	printerr(descr)

func _exit_tree():
	for thread in threads:
		if thread.is_active():
			thread.wait_to_finish()