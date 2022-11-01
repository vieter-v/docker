module docker

import json
import time
import net.http { Method }
import types { ContainerListItem }

[params]
pub struct ContainerListConfig {
	all     bool
	limit   int
	size    bool
	filters map[string][]string
}

pub fn (mut d DockerConn) container_list(c ContainerListConfig) ![]ContainerListItem {
	d.get('/containers/json')
	d.params(c)
	d.send()!

	return d.read_json_response<[]ContainerListItem>()
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
	d.send_request_with_json(Method.post, '/containers/create', c)!
	head, res := d.read_response()!

	if head.status_code != 201 {
		data := json.decode(DockerError, res)!

		return error(data.message)
	}

	data := json.decode(CreatedContainer, res)!

	return data
}

// start_container starts the container with the given id.
pub fn (mut d DockerConn) container_start(id string) ! {
	d.send_request(Method.post, '/containers/$id/start')!
	head, body := d.read_response()!

	if head.status_code != 204 {
		data := json.decode(DockerError, body)!

		return error(data.message)
	}
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
	d.send_request(Method.get, '/containers/$id/json')!
	head, body := d.read_response()!

	if head.status_code != 200 {
		data := json.decode(DockerError, body)!

		return error(data.message)
	}

	mut data := json.decode(ContainerInspect, body)!

	// The Docker engine API *should* always return UTC time.
	data.state.start_time = time.parse_rfc3339(data.state.start_time_str)!

	if data.state.status == 'exited' {
		data.state.end_time = time.parse_rfc3339(data.state.end_time_str)!
	}

	return data
}

pub fn (mut d DockerConn) container_remove(id string) ! {
	d.send_request(Method.delete, '/containers/$id')!
	head, body := d.read_response()!

	if head.status_code != 204 {
		data := json.decode(DockerError, body)!

		return error(data.message)
	}
}

pub fn (mut d DockerConn) container_get_logs(id string) !&StreamFormatReader {
	d.send_request(Method.get, '/containers/$id/logs?stdout=true&stderr=true')!
	head := d.read_response_head()!

	if head.status_code != 200 {
		content_length := head.header.get(http.CommonHeader.content_length)!.int()
		body := d.read_response_body(content_length)!
		data := json.decode(DockerError, body)!

		return error(data.message)
	}

	return d.get_stream_format_reader()
}
