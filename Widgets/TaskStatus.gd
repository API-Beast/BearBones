extends Control

export var visibility_time_out = 0.0
export var error_time_out = 2.0
var visibility_timer = 0.0
var hide = false

func _ready():
	Jobs.connect("job_status_changed", self, "update_task")
	update_task()

func update_task():
	if !is_inside_tree():
		return

	var active = Jobs.current_jobs.size() > 0
	if active:
		self.visible = true
		hide = false
		$Layout/AnimationPlayer.current_animation = "Active"
		$Layout/Label.text = Jobs.current_jobs.front()
	else:
		hide = true
		if Jobs.errors.empty():
			$Layout/AnimationPlayer.current_animation = "Finished"
			$Layout/Label.text = tr("All Jobs finished.")
			visibility_timer = visibility_time_out
		else:
			$Layout/AnimationPlayer.current_animation = "Error"
			$Layout/Label.text = Jobs.errors.back()
			visibility_timer = error_time_out

func _process(dt):
	if hide:
		visibility_timer -= dt
		if visibility_timer < 0.0:
			self.visible = false
			hide = false