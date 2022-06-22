module docker

import json
import time
import net.http { Method }

pub struct Port {
	ip           string [json: IP]
	private_port u16    [json: PrivatePort]
	public_port  u16    [json: PublicPort]
	type_        string [json: Type]
}

pub struct HostConfig {
	network_mode string [json: NetworkMode]
}

pub struct EndpointIpamConfig {
	ipv4_address   string   [json: IPv4Address]
	ipv6_address   string   [json: IPv6Address]
	link_local_ips []string [json: LinkLocalIPs]
}

pub struct EndpointSettings {
	ipam_config            EndpointIpamConfig [json: IPAMConfig]
	links                  []string           [json: Links]
	aliases                []string           [json: Aliases]
	network_id             string             [json: NetworkID]
	endpoint_id            string             [json: EndpointID]
	gateway                string             [json: Gateway]
	ip_address             string             [json: IPAddress]
	ip_prefix_len          int                [json: IPPrefixLen]
	ipv6_gateway           string             [json: IPv6Gateway]
	global_ipv6_address    string             [json: GlobalIPv6Address]
	global_ipv6_prefix_len i64                [json: GlobalIPv6PrefixLen]
	mac_address            string             [json: MacAddress]
	driver_opts            map[string]string  [json: DriverOpts]
}

pub struct NetworkSettings {
	networks map[string]EndpointSettings [json: Networks]
}

pub struct MountPoint {
	type_       string [json: Type]
	name        string [json: Name]
	source      string [json: Source]
	destination string [json: Destination]
	driver      string [json: Driver]
	mode        string [json: Mode]
	rw          bool   [json: RW]
	propagation string [json: Propagation]
}

pub struct ContainerListItem {
	id               string            [json: Id]
	names            []string          [json: Names]
	image            string            [json: Image]
	image_id         string            [json: ImageID]
	command          string            [json: Command]
	created          i64               [json: Created]
	ports            []Port            [json: Ports]
	size_rw          i64               [json: SizeRw]
	size_root_fs     i64               [json: SizeRootFs]
	labels           map[string]string [json: Labels]
	state            string            [json: State]
	status           string            [json: Status]
	host_config      HostConfig        [json: HostConfig]
	network_settings NetworkSettings   [json: NetworkSettings]
	mounts           []MountPoint      [json: Mounts]
}

pub fn (mut d DockerConn) container_list() ?[]ContainerListItem {
	d.send_request(Method.get, '/containers/json')?

	data := d.read_json_response<[]ContainerListItem>()?

	return data
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

pub fn (mut d DockerConn) container_create(c NewContainer) ?CreatedContainer {
	d.send_request_with_json(Method.post, '/containers/create', c)?
	head, res := d.read_response()?

	if head.status_code != 201 {
		data := json.decode(DockerError, res)?

		return error(data.message)
	}

	data := json.decode(CreatedContainer, res)?

	return data
}

// start_container starts the container with the given id.
pub fn (mut d DockerConn) container_start(id string) ? {
	d.send_request(Method.post, 'containers/$id/start')?
	head, body := d.read_response()?

	if head.status_code != 204 {
		data := json.decode(DockerError, body)?

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

pub fn (mut d DockerConn) container_inspect(id string) ?ContainerInspect {
	d.send_request(Method.get, 'containers/$id/json')?
	head, body := d.read_response()?

	if head.status_code != 200 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	mut data := json.decode(ContainerInspect, body)?

	// The Docker engine API *should* always return UTC time.
	data.state.start_time = time.parse_rfc3339(data.state.start_time_str)?

	if data.state.status == 'exited' {
		data.state.end_time = time.parse_rfc3339(data.state.end_time_str)?
	}

	return data
}

pub fn (mut d DockerConn) container_remove(id string) ? {
	d.send_request(Method.delete, 'containers/$id')?
	head, body := d.read_response()?

	if head.status_code != 204 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}
}

pub fn (mut d DockerConn) container_get_logs(id string) ?&StreamFormatReader {
	d.send_request(Method.get, 'containers/$id/logs?stdout=true&stderr=true')?
	head := d.read_response_head()?

	if head.status_code != 200 {
		content_length := head.header.get(http.CommonHeader.content_length)?.int()
		body := d.read_response_body(content_length)?
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	return d.get_stream_format_reader()
}
