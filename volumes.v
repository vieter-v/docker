module vdocker

import net.http { Method }
import net.urllib
import json
import time

struct UsageData {
	size      int [json: Size]
	ref_count int [json: RefCount]
}

struct Volume {
	created_at_str string [json: CreatedAt]
pub mut:
	name       string            [json: Name]
	driver     string            [json: Driver]
	mountpoint string            [json: Mountpoint]
	created_at time.Time         [skip]
	status     map[string]string [json: Status]
	labels     map[string]string [json: Labels]
	scope      string            [json: Scope]
	options    map[string]string [json: Options]
	usage_data UsageData         [json: UsageData]
}

struct VolumeListResponse {
	volumes  []Volume [json: Volumes]
	warnings []string [json: Warnings]
}

pub fn (mut d DockerConn) volume_list() ?VolumeListResponse {
	d.send_request(Method.get, urllib.parse('/v1.41/volumes')?)?
	head, body := d.read_response()?

	if head.status_code != 200 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	mut data := json.decode(VolumeListResponse, body)?

	for mut vol in data.volumes {
		vol.created_at = time.parse_rfc3339(vol.created_at_str)?
	}

	return data
}
