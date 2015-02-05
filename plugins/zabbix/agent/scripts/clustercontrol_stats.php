<?php
/*
clustercontrol_stats.php <cluster_id> <options>
Supported options: test, backup, cluster, alarms-critical, alarms-warning
*/

array_shift($argv);
$cluster_id = $argv[0];
$arg1 = $argv[1];

switch ($arg1) {
	case 'backup':
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
	$ncid = explode(",",$cid);
	$arr = array();
	if ( $arg == 'clusters/all' ) {
		$arr = json_decode(call_cmonapi($ncid[0],$arg));
	}
	else {
		foreach ($ncid as $value) {
			array_push($arr,json_decode(call_cmonapi($value,$arg)));
		}
	}

	//print_r($arr);
	if ( $arg == 'backups/all' ) {
		if (empty($arr->data)) {
			$i=0;
		}
		else {
			$i=0;
			foreach ( $arr as $obj ) {
				if ( $obj->data->error != 0 ) {
					$i++;
				}
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
		foreach ( $arr as $a ) {
			$cluster_status = $a->data->status;

			if ( $cluster_status == 'FAILURE' || $cluster_status == 'CRITICAL' || $cluster_status == 'STOPPED' || $cluster_status == 'SHUTTING_DOWN' ) {
				$retval=0;
				break;
			}
			elseif ( $cluster_status == 'DEGRADED' ) {
				$retval=2;
				break;
			}
			elseif ( $cluster_status == 'ACTIVE' || $cluster_status == 'STARTED') {
				$retval=1;
				continue;
			}
			else { //unknown
				$retval=3;
				break;
			}
		}

		return $retval;

	}
	elseif ( $arg == 'clusters/all' ) {
		foreach ( $arr->data as $obj ) {
			echo 'Cluster ID: '. strtoupper($obj->id) . ', Type: ' . strtoupper($obj->type) . ", Status: " . strtoupper($obj->status) . "\n" ;
		}
	}
	elseif ( $arg == 'alarms/all' && $xopt == 'warning' ){
		$i=0;
		//print_r($arr);
		foreach ( $arr as $obj ) {
			foreach ($obj->data as $data) {
				if ( $data->ignored == 0 && strtoupper($data->severity) == "WARNING" ) {
					$i++;
				}
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
		foreach ( $arr as $obj ) {
			foreach ($obj->data as $data) {
				if ( $data->ignored == 0 && strtoupper($data->severity) == "CRITICAL" ) {
					$i++;
				}
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