module docker

import net.http { Method }
import types { Image }
import json

pub fn (mut d DockerConn) image_inspect(image string) !Image {
	d.send_request(.get, '/images/$image/json')!
	_, body := d.read_response()!

	data := json.decode(Image, body)!

	return data
}

// pull_image pulls the given image:tag.
pub fn (mut d DockerConn) pull_image(image string, tag string) ! {
	d.send_request(Method.post, '/images/create?fromImage=$image&tag=$tag')!
	head := d.read_response_head()!

	if head.status().is_error() {
		content_length := head.header.get(.content_length)!.int()
		body := d.read_response_body(content_length)!
		mut err := json.decode(DockerError, body)!
		err.status = head.status_code

		return err
	}

	// Keep reading the body until the pull has completed
	mut body := d.get_chunked_response_reader()

	mut buf := []u8{len: 1024}

	for {
		body.read(mut buf) or { break }
	}
}

// create_image_from_container creates a new image from a container.
pub fn (mut d DockerConn) create_image_from_container(id string, repo string, tag string) !Image {
	d.send_request(.post, '/commit?container=$id&repo=$repo&tag=$tag')!
	_, body := d.read_response()!

	data := json.decode(Image, body)!

	return data
}

// remove_image removes the image with the given id.
pub fn (mut d DockerConn) remove_image(id string) ! {
	d.send_request(.delete, '/images/$id')!
	d.read_response()!
}
