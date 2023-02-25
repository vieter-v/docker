module docker

import net.http
import net.urllib
import io
import json

fn (mut d DockerConn) request(method http.Method, url string) {
	d.method = method
	d.url = url
	d.content_type = ''
	d.body = ''

	d.params.clear()
}

fn (mut d DockerConn) body(content_type string, body string) {
	d.content_type = content_type
	d.body = body
}

fn (mut d DockerConn) body_json[T](data T) {
	d.content_type = 'application/json'
	d.body = json.encode(data)
}

fn (mut d DockerConn) params[T](o T) {
	$if T is map[string]string {
		for key, value in o {
			d.params[key] = urllib.query_escape(value.replace("'", '"'))
		}
	} $else {
		$for field in T.fields {
			v := o.$(field.name)

			if !isnil(v) {
				d.params[field.name] = urllib.query_escape(v.str().replace("'", '"'))
			}
		}
	}
}

fn (mut d DockerConn) send() ! {
	mut full_url := '/${docker.api_version}${d.url}'

	if d.params.len > 0 {
		mut fields := []string{cap: d.params.len}

		for key, value in d.params {
			fields << '${key}=${value}'
		}
		params_str := fields.join('&')
		// params_str := d.params.keys().map('${it}=${d.params[it]}').join('&')
		full_url += '?${params_str}'
	}

	// This is to make sure we actually created a valid URL
	parsed_url := urllib.parse(full_url)!
	final_url := parsed_url.request_uri()

	req := if d.body == '' {
		'${d.method} ${final_url} HTTP/1.1\nHost: localhost\n\n'
	} else {
		'${d.method} ${final_url} HTTP/1.1\nHost: localhost\nContent-Type: ${d.content_type}\nContent-Length: ${d.body.len}\n\n${d.body}\n\n'
	}

	d.socket.write_string(req)!

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}
