module vdocker

struct DockerError {
    status int [skip]
	message string
}

fn (err DockerError) code() int {
    return err.status
}

fn (err DockerError) msg() string {
    return err.message
}

fn docker_error(status int, message string) IError {
    return IError(DockerError{
        status: status
        message: message
    })
}
