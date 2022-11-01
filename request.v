module docker

import net.http
import net.urllib
import io

fn (mut d DockerConn) request(method http.Method, url_str string) {
	d.method = method
	d.url = url_str
	d.params.clear()
	d.content_type = ''
	d.body = ''
}

fn (mut d DockerConn) get(url_str string) {
	d.request(http.Method.get, url_str)
}

fn (mut d DockerConn) params<T>(o T) {
	$for field in T.fields {
		v := o.$(field.name)

		if !isnil(v) {
			d.params[field.name] = urllib.query_escape(v.str().replace("'", '"'))
		}
	}
}

fn (mut d DockerConn) send() ! {
	mut full_url := d.url

	if d.params.len > 0 {
		params_str := d.params.keys().map('$it=${d.params[it]}').join('&')
		full_url += '?$params_str'
	}

	// This is to make sure we actually created a valid URL
	parsed_url := urllib.parse(full_url)!
	final_url := parsed_url.request_uri()

	req := if d.body == '' {
		'$d.method $final_url HTTP/1.1\nHost: localhost\n\n'
	} else {
		'$d.method $final_url HTTP/1.1\nHost: localhost\nContent-Type: $d.content_type\nContent-Length: $d.body.len\n\n$d.body\n\n'
	}

	d.socket.write_string(req)!

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}
