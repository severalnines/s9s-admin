<?php
/*
clustercontrol_stats.php <cluster_id> <options>
Supported options: test, backups, cluster, alarms-critical, alarms-warning
*/

array_shift($argv);
$cluster_id = $argv[0];
$arg1 = $argv[1];

switch ($arg1) {
	case 'backups':
		process_data ($cluster_id, "backups/all", "cmonapi");
		break;
	case 'cluster':
		process_data ($cluster_id, "clusters/info", "cmonapi");
		break;
	case 'alarms-warning':
		process_data ($cluster_id, "alarms/all", "cmonapi");
		break;
	case 'alarms-critical':
		process_data ($cluster_id, "alarms/all", "cmonapi", "critical");
		break;
	case 'test':
		process_data ($cluster_id, "clusters/all", "cmonapi");
		break;
	default:
		echo 'Error: Unknown option. Supported option: test|backups|cluster|alarms-critical|alarms-warning';
		break;
}

function process_data ($cid, $arg, $method, $extra = 'warning') {
	if ( $method == "cmonapi" ){
		echo process_cmonapi($cid,$arg,$extra);
	}
	else {
		echo "Unknown calling method. Please either specify cmonapi or cmonrpc.";
		exit (1);
	}
}

function call_cmonapi ( $cid, $arg ) {
	return shell_exec("./clustercontrol_api.sh -i {$cid} -r {$arg}");
}

function process_cmonapi ( $cid, $arg, $xopt ) {
	$arr = json_decode(call_cmonapi($cid,$arg));
	if ( $arg == 'backups/all' ) {
		$i=0;
		foreach ( $arr->data as $obj ) {
			if ( $obj->error != 0 ) {
				$i++;
			}
		}
		if ( $i == 0 ){
			return 0;
		}
		else {
			return 1;
		}
	} 
	elseif ( $arg == 'clusters/info' ) {
		$cluster_status = strtoupper($arr->data->status);
		switch ($cluster_status) {
			case 'FAILURE':
			case 'CRITICAL':
			case 'STOPPED':
			case 'SHUTTING_DOWN':
				return 0; 
				break;
			case 'DEGRADED':
				return 2; 
				break;
			case 'ACTIVE':
			case 'STARTED':
				return 1; 
				break;
			default: //unknown
				return 3; 
				break;
		}
	}
	elseif ( $arg == 'clusters/all' ) {
		$cluster_type = strtoupper($arr->data[0]->type);
		return $cluster_type;
	}
	elseif ( $arg == 'alarms/all' && $xopt == 'warning' ){
		$i=0;
		foreach ( $arr->data as $obj ) {
			if ( $obj->ignored == 0 && strtoupper($obj->severity) == "WARNING" ) {
				$i++;
			}
		}
		if ( $i != 0 ){
			return $i;
		}
		else {
			return 0;
		}
	}
	elseif ( $arg == 'alarms/all' && $xopt == 'critical' ){
		$i=0;
		foreach ( $arr->data as $obj ) {
			//var_dump($obj->ignored);
			if ( $obj->ignored == 0 && strtoupper($obj->severity) == "CRITICAL" ) {
				$i++;
			}
		}
		if ( $i != 0 ){
			return $i;
		}
		else {
			return 0;
		}
	}
	else {
		echo 'Error: Unknown options';
	}
}

?>