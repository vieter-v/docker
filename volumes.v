module vdocker

import net.http { Method }
import net.urllib
import json
import time

struct Volume {
	name       string    [json: Name]
	driver     string    [json: Driver]
	mountpoint string    [json: Mountpoint]
	created_at time.Time [json: CreatedAt]
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

	data := json.decode(VolumeListResponse, body)?

	return data
}
