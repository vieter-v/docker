module docker

import net.unix
import io
import net.http
import strings
import net.urllib
import json
import util

const (
	socket               = '/var/run/docker.sock'
	buf_len              = 10 * 1024
	http_separator       = [u8(`\r`), `\n`, `\r`, `\n`]
	http_chunk_separator = [u8(`\r`), `\n`]
	timestamp_attr       = 'timestamp'
	api_version          = 'v1.41'
)

[heap]
pub struct DockerConn {
mut:
	socket &unix.StreamConn
	reader &io.BufferedReader
	// Data for the request that's currently being constructed.
	method       http.Method
	url          string
	params       map[string]string
	content_type string
	head         http.Response
	body         string
}

// new_conn creates a new connection to the Docker daemon.
pub fn new_conn() !&DockerConn {
	s := unix.connect_stream(docker.socket)!

	d := &DockerConn{
		socket: s
		reader: io.new_buffered_reader(reader: s)
	}

	return d
}

// close closes the underlying socket connection.
pub fn (mut d DockerConn) close() ! {
	d.socket.close()!
}

// send_request sends an HTTP request without body.
fn (mut d DockerConn) send_request(method http.Method, url_str string) ! {
	url := urllib.parse('/$docker.api_version$url_str')!
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n'

	d.socket.write_string(req)!

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}

// send_request_with_body sends an HTTP request with the given body.
fn (mut d DockerConn) send_request_with_body(method http.Method, url_str string, content_type string, body string) ! {
	url := urllib.parse('/$docker.api_version$url_str')!
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\nContent-Type: $content_type\nContent-Length: $body.len\n\n$body\n\n'

	d.socket.write_string(req)!

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}

// send_request_with_json<T> is a convenience wrapper around
// send_request_with_body that encodes the input as JSON.
fn (mut d DockerConn) send_request_with_json<T>(method http.Method, url_str string, data &T) ! {
	body := json.encode(data)

	return d.send_request_with_body(method, url_str, 'application/json', body)
}

// read_response_head consumes the socket's contents until it encounters
// '\r\n\r\n', after which it parses the response as an HTTP response.
// Importantly, this function never consumes the reader past the HTTP
// separator, so the body can be read fully later on.
fn (mut d DockerConn) read_response_head() ! {
	mut res := []u8{}

	util.read_until_separator(mut d.reader, mut res, docker.http_separator)!

	d.head = http.parse_response(res.bytestr())!
}

fn (mut d DockerConn) read_response_body() ! {
    if d.head.status() == .no_content {
        return
    }

	if d.head.header.get(http.CommonHeader.transfer_encoding) or { '' } == 'chunked' {
		mut builder := strings.new_builder(1024)
		mut body := d.get_chunked_response_reader()

		util.reader_to_writer(mut body, mut builder)!
		d.body = builder.str()

        return
	}

	content_length := d.head.header.get(.content_length)!.int()

	if content_length == 0 {
		return
	}

	mut buf := []u8{len: docker.buf_len}
	mut c := 0
	mut builder := strings.new_builder(docker.buf_len)

	for builder.len < content_length {
		c = d.reader.read(mut buf)!

		builder.write(buf[..c])!
	}

	d.body = builder.str()
}

// read_response is a convenience function which always consumes the entire
// response and loads it into memory. It should only be used when we're certain
// that the result isn't too large, as even chunked responses will get fully
// loaded into memory.
fn (mut d DockerConn) read_response() ! {
	d.read_response_head()!
	d.check_error()!
    d.read_response_body()!
}

// read_json_response<T> is a convenience function that runs read_response
// before parsing its contents, which is assumed to be JSON, into a struct.
fn (mut d DockerConn) read_json_response<T>() !T {
	d.read_response()!

	data := json.decode(T, d.body)!

	//$for field in T.fields {
	//$if field.typ is time.Time {
	// data.$(field.name) = time.parse_rfc3339(data.$(field.name + '_str'))?
	//}
	//}

	return data
}

// get_chunked_response_reader returns a ChunkedResponseReader using the socket
// as reader.
fn (mut d DockerConn) get_chunked_response_reader() &ChunkedResponseReader {
	r := new_chunked_response_reader(d.reader)

	return r
}

// get_stream_format_reader returns a StreamFormatReader using the socket as
// reader.
fn (mut d DockerConn) get_stream_format_reader() &StreamFormatReader {
	r := new_chunked_response_reader(d.reader)
	r2 := new_stream_format_reader(r)

	return r2
}

struct DockerError {
pub:
	message string
}

// check_error should be called after read_response_head. If the status code of
// the response is an error, the body is consumed and the Docker HTTP error is
// returned as a V error. If the status isn't the error, this function is a
// no-op.
fn (mut d DockerConn) check_error() ! {
	if d.head.status().is_error() {
		d.read_response_body()!
		d_err := json.decode(DockerError, d.body)!

		return error_with_code('$d.head.status(): $d_err.message', d.head.status_code)
	}
}
