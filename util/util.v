module util

import io

// reader_to_writer tries to consume the entire reader & write it to the writer.
pub fn reader_to_writer(mut reader io.Reader, mut writer io.Writer) ! {
	mut buf := []u8{len: 10 * 1024}

	for {
		bytes_read := reader.read(mut buf) or { break }
		mut bytes_written := 0

		for bytes_written < bytes_read {
			c := writer.write(buf[bytes_written..bytes_read]) or { break }

			bytes_written += c
		}
	}
}

// match_array_in_array<T> returns how many elements of a2 overlap with a1. For
// example, if a1 = "abcd" & a2 = "cd", the result will be 2. If the match is
// not at the end of a1, the result is 0.
pub fn match_array_in_array[T](a1 []T, a2 []T) int {
	mut i := 0
	mut match_len := 0

	for i + match_len < a1.len {
		if a1[i + match_len] == a2[match_len] {
			match_len += 1
		} else {
			i += match_len + 1
			match_len = 0
		}
	}

	return match_len
}

// read_until_separator consumes an io.Reader until it encounters some
// separator array. The data read is stored inside the provided res array.
pub fn read_until_separator(mut reader io.Reader, mut res []u8, sep []u8) ! {
	mut buf := []u8{len: sep.len}

	for {
		c := reader.read(mut buf)!
		res << buf[..c]

		match_len := match_array_in_array(buf[..c], sep)

		if match_len == sep.len {
			break
		}

		if match_len > 0 {
			match_left := sep.len - match_len
			c2 := reader.read(mut buf[..match_left])!
			res << buf[..c2]

			if buf[..c2] == sep[match_len..] {
				break
			}
		}
	}
}
