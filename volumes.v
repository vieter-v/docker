module vdocker

import net.http { Method }
import time

struct UsageData {
	size      int [json: Size]
	ref_count int [json: RefCount]
}

struct Volume {
	created_at_str string [json: CreatedAt]
pub mut:
	created_at time.Time         [skip]
	name       string            [json: Name]
	driver     string            [json: Driver]
	mountpoint string            [json: Mountpoint]
	status     map[string]string [json: Status]
	labels     map[string]string [json: Labels]
	scope      string            [json: Scope]
	options    map[string]string [json: Options]
	usage_data UsageData         [json: UsageData]
}

[params]
pub struct VolumeListFilter {
	dangling bool
	driver   string
	labels   []string
	name     string
}

struct VolumeListResponse {
	volumes  []Volume [json: Volumes]
	warnings []string [json: Warnings]
}

pub fn (mut d DockerConn) volume_list() ?VolumeListResponse {
	d.send_request(Method.get, '/volumes')?

	mut data := d.read_json_response<VolumeListResponse>()?

	for mut vol in data.volumes {
		vol.created_at = time.parse_rfc3339(vol.created_at_str)?
	}

	return data
}
