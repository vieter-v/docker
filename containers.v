module docker

import time
import types { ContainerListItem }

[params]
pub struct ContainerListConfig {
	all     bool
	limit   int
	size    bool
	filters map[string][]string
}

pub fn (mut d DockerConn) container_list(c ContainerListConfig) ![]ContainerListItem {
	d.request(.get, '/containers/json')
	d.params(c)
	d.send()!

	return d.read_json_response[[]ContainerListItem]()
}

pub struct NewContainer {
	image      string   [json: Image]
	entrypoint []string [json: Entrypoint]
	cmd        []string [json: Cmd]
	env        []string [json: Env]
	work_dir   string   [json: WorkingDir]
	user       string   [json: User]
}

struct CreatedContainer {
pub:
	id       string   [json: Id]
	warnings []string [json: Warnings]
}

pub fn (mut d DockerConn) container_create(c NewContainer) !CreatedContainer {
	d.request(.post, '/containers/create')
	d.body_json(c)
	d.send()!

	return d.read_json_response[CreatedContainer]()
}

// start_container starts the container with the given id.
pub fn (mut d DockerConn) container_start(id string) ! {
	d.request(.post, '/containers/${id}/start')
	d.send()!
	d.read_response()!
}

struct ContainerInspect {
pub mut:
	state ContainerState [json: State]
}

struct ContainerState {
pub:
	running   bool   [json: Running]
	status    string [json: Status]
	exit_code int    [json: ExitCode]
	// These use a rather specific format so they have to be parsed later
	start_time_str string [json: StartedAt]
	end_time_str   string [json: FinishedAt]
pub mut:
	start_time time.Time [skip]
	end_time   time.Time [skip]
}

pub fn (mut d DockerConn) container_inspect(id string) !ContainerInspect {
	d.request(.get, '/containers/${id}/json')
	d.send()!

	mut data := d.read_json_response[ContainerInspect]()!

	// The Docker engine API *should* always return UTC time.
	data.state.start_time = time.parse_rfc3339(data.state.start_time_str)!

	if data.state.status == 'exited' {
		data.state.end_time = time.parse_rfc3339(data.state.end_time_str)!
	}

	return data
}

pub fn (mut d DockerConn) container_remove(id string) ! {
	d.request(.delete, '/containers/${id}')
	d.send()!
	d.read_response()!
}

pub fn (mut d DockerConn) container_kill(id string) ! {
	d.request(.post, '/containers/${id}/kill')
	d.send()!
	d.read_response()!
}

pub fn (mut d DockerConn) container_get_logs(id string) !&StreamFormatReader {
	d.request(.get, '/containers/${id}/logs')
	d.params({
		'stdout': 'true'
		'stderr': 'true'
	})
	d.send()!
	d.read_response_head()!
	d.check_error()!

	return d.get_stream_format_reader()
}
