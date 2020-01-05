extends Node

var current_jobs = []
var errors = []

signal job_finished(job)
signal job_failed(job, error)

signal job_status_changed()
signal all_jobs_finished()

func start_job(job):
	current_jobs.push_back(job)