module docker

import time
import types { Volume }

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

pub fn (mut d DockerConn) volume_list() !VolumeListResponse {
	d.request(.get, '/volumes', {})
	d.send()!

	mut data := d.read_json_response<VolumeListResponse>()!

	for mut vol in data.volumes {
		vol.created_at = time.parse_rfc3339(vol.created_at_str)!
	}

	return data
}
