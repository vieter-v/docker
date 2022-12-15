module docker

struct DockerError {
pub mut:
	status  int    [skip]
	message string
}

fn (err DockerError) code() int {
	return err.status
}

fn (err DockerError) msg() string {
	return err.message
}

fn docker_error(status int, message string) DockerError {
	return DockerError{
		status: status
		message: message
	}
}
