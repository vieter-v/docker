module types

pub struct Port {
	ip           string [json: IP]
	private_port u16    [json: PrivatePort]
	public_port  u16    [json: PublicPort]
	type_        string [json: Type]
}

pub struct HostConfig {
	network_mode string [json: NetworkMode]
}

pub struct EndpointIpamConfig {
	ipv4_address   string   [json: IPv4Address]
	ipv6_address   string   [json: IPv6Address]
	link_local_ips []string [json: LinkLocalIPs]
}

pub struct EndpointSettings {
	ipam_config            EndpointIpamConfig [json: IPAMConfig]
	links                  []string           [json: Links]
	aliases                []string           [json: Aliases]
	network_id             string             [json: NetworkID]
	endpoint_id            string             [json: EndpointID]
	gateway                string             [json: Gateway]
	ip_address             string             [json: IPAddress]
	ip_prefix_len          int                [json: IPPrefixLen]
	ipv6_gateway           string             [json: IPv6Gateway]
	global_ipv6_address    string             [json: GlobalIPv6Address]
	global_ipv6_prefix_len i64                [json: GlobalIPv6PrefixLen]
	mac_address            string             [json: MacAddress]
	driver_opts            map[string]string  [json: DriverOpts]
}

pub struct NetworkSettings {
	networks map[string]EndpointSettings [json: Networks]
}

pub struct MountPoint {
	type_       string [json: Type]
	name        string [json: Name]
	source      string [json: Source]
	destination string [json: Destination]
	driver      string [json: Driver]
	mode        string [json: Mode]
	rw          bool   [json: RW]
	propagation string [json: Propagation]
}

pub struct ContainerListItem {
	id               string            [json: Id]
	names            []string          [json: Names]
	image            string            [json: Image]
	image_id         string            [json: ImageID]
	command          string            [json: Command]
	created          i64               [json: Created]
	ports            []Port            [json: Ports]
	size_rw          i64               [json: SizeRw]
	size_root_fs     i64               [json: SizeRootFs]
	labels           map[string]string [json: Labels]
	state            string            [json: State]
	status           string            [json: Status]
	host_config      HostConfig        [json: HostConfig]
	network_settings NetworkSettings   [json: NetworkSettings]
	mounts           []MountPoint      [json: Mounts]
}
