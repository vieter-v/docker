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
fn (mut d DockerConn) read_response_head() !http.Response {
	mut res := []u8{}

	util.read_until_separator(mut d.reader, mut res, docker.http_separator)!

	return http.parse_response(res.bytestr())
}

// read_response_body reads `length` bytes from the stream. It can be used when
// the response encoding isn't chunked to fully read it.
fn (mut d DockerConn) read_response_body(length int) !string {
	if length == 0 {
		return ''
	}

	mut buf := []u8{len: docker.buf_len}
	mut c := 0
	mut builder := strings.new_builder(docker.buf_len)

	for builder.len < length {
		c = d.reader.read(mut buf) or { break }

		builder.write(buf[..c])!
	}

	return builder.str()
}

// read_response is a convenience function which always consumes the entire
// response & returns it. It should only be used when we're certain that the
// result isn't too large.
fn (mut d DockerConn) read_response() !(http.Response, string) {
	head := d.read_response_head()!

    // 204 means "No Content", so we can assume nothing follows after this
    if head.status_code == 204 {
        return head, ''      
    }

	if head.header.get(http.CommonHeader.transfer_encoding) or { '' } == 'chunked' {
		mut builder := strings.new_builder(1024)
		mut body := d.get_chunked_response_reader()

		util.reader_to_writer(mut body, mut builder)!

		return head, builder.str()
	}

	content_length := head.header.get(http.CommonHeader.content_length)!.int()
	res := d.read_response_body(content_length)!

	return head, res
}

fn (mut d DockerConn) read_json_response<T>() !T {
	head, body := d.read_response()!

	if head.status_code < 200 || head.status_code > 300 {
		data := json.decode(DockerError, body)!

		return docker_error(head.status_code, data.message)
	}

	mut data := json.decode(T, body)!

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
