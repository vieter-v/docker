module docker

import types { Image }

pub fn (mut d DockerConn) image_inspect(image string) !Image {
	d.request(.get, '/images/$image/json', {})
	d.send()!

	data := d.read_json_response<Image>()!

	return data
}

// image_pull pulls the given image:tag.
pub fn (mut d DockerConn) image_pull(image string, tag string) ! {
	d.request(.post, '/images/create', {
		'fromImage': image
		'tag':       tag
	})
	d.send()!
	d.read_response_head()!
	d.check_error()!

	// Keep reading the body until the pull has completed
	mut body := d.get_chunked_response_reader()

	mut buf := []u8{len: 1024}

	for {
		body.read(mut buf) or { break }
	}
}

// create_image_from_container creates a new image from a container.
pub fn (mut d DockerConn) image_from_container(id string, repo string, tag string) !Image {
	d.request(.post, '/commit', {
		'container': id
		'repo':      repo
		'tag':       tag
	})
	d.send()!

	return d.read_json_response<Image>()!
}

// remove_image removes the image with the given id.
pub fn (mut d DockerConn) image_remove(id string) ! {
	d.request(.delete, '/images/$id', {})
	d.send()!
	d.read_response()!
}
