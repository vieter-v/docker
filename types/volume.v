module types

import time

pub struct UsageData {
	size      int [json: Size]
	ref_count int [json: RefCount]
}

pub struct Volume {
pub mut:
	created_at_str string            [json: CreatedAt]
	created_at     time.Time         [skip]
	name           string            [json: Name]
	driver         string            [json: Driver]
	mountpoint     string            [json: Mountpoint]
	status         map[string]string [json: Status]
	labels         map[string]string [json: Labels]
	scope          string            [json: Scope]
	options        map[string]string [json: Options]
	usage_data     UsageData         [json: UsageData]
}
