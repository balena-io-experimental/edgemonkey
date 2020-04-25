export enum RepairActions {
	cleanup = 'cleanup',
	remove_application_lock = 'remove_application_lock',
	remove_fill_files = 'remove_fill_files',
	restore_dns = 'restore_dns',
	restore_random_subnets = 'restore_random_subnets',
	restore_vpn = 'restore_vpn',
}

export enum DestroyActions {
	drop_dns = 'drop_dns',
	drop_random_subnet = 'drop_random_subnet',
	drop_vpn = 'drop_vpn',
	fill_random_data_dir = 'fill_random_data_dir',
	force_update = 'force_update',
	global_drop_packets = 'global_drop_packets',
	global_limit_bandwidth = 'global_limit_bandwidth',
	global_restore_bandwidth = 'global_restore_bandwidth',
	global_restore_packet_drop = 'global_restore_packet_drop',
	global_restore_throttle = 'global_restore_throttle',
	global_throttle_traffic = 'global_throttle_traffic',
	restart_all_apps = 'restart_all_apps',
	restart_app = 'restart_app',
	restart_dns = 'restart_dns',
	restart_engine = 'restart_engine',
	restart_network = 'restart_network',
	restart_supervisor = 'restart_supervisor',
	restart_timesync = 'restart_timesync',
	restart_unit = 'restart_unit',
	restart_vpn = 'restart_vpn',
	stop_app = 'stop_app',
	take_application_lock = 'take_application_lock',
}

export const Actions = { ...DestroyActions, ...RepairActions };
