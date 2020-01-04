extends Control

export var visibility_time_out = 0.0
export var error_time_out = 2.0
var visibility_timer = 0.0
var hide = false

func _ready():
	Tasks.connect("task_status_changed", self, "update_task")
	update_task()

func update_task():
	if !is_inside_tree():
		return

	var active = Tasks.num_tasks > 0
	if active:
		self.visible = true
		hide = false
		$Layout/AnimationPlayer.current_animation = "Active"
		$Layout/Label.text = Tasks.tasks.values().front()
	else:
		hide = true
		if Tasks.errors.empty():
			$Layout/AnimationPlayer.current_animation = "Finished"
			$Layout/Label.text = tr("All Tasks finished.")
			visibility_timer = visibility_time_out
		else:
			$Layout/AnimationPlayer.current_animation = "Error"
			$Layout/Label.text = Tasks.errors.back()
			visibility_timer = error_time_out

func _process(dt):
	if hide:
		visibility_timer -= dt
		if visibility_timer < 0.0:
			self.visible = false
			hide = false