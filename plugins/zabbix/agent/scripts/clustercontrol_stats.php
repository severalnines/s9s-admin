<?php
/*
clustercontrol_stats.php <cluster_id> <options>
Supported options: test, cluster, alarms-critical, alarms-warning
*/

//*** Specify the absolute path to ClusterControl's bootstrap.php file. ***//

$BOOTSTRAP_PATH='/var/www/html/clustercontrol/bootstrap.php';



// Ensure bootstrap.php is copied before include
$BOOTSTRAP_FILE= 'bootstrap.php';

if (file_exists($BOOTSTRAP_FILE)) {
	include_once ($BOOTSTRAP_FILE);
}
else {
	if (copy($BOOTSTRAP_PATH,$BOOTSTRAP_FILE)) {
		chmod($BOOTSTRAP_FILE, 644);
		include_once ($BOOTSTRAP_FILE);
	} else {
		echo "Failed to copy $BOOTSTRAP_PATH to $BOOTSTRAP_FILE\n";
	}
}

array_shift($argv);
$cluster_id = $argv[0];
$arg1 = $argv[1];

switch ($arg1) {
	case 'cluster':
		process_data ($cluster_id, "cluster-rpc", "cmonrpc");
		break;
	case 'alarms-warning':
		process_data ($cluster_id, "alarms", "cmonrpc", "warning");
		break;
	case 'alarms-critical':
		process_data ($cluster_id, "alarms", "cmonrpc", "critical");
		break;
	case 'test':
		process_data ($cluster_id, "test-rpc", "cmonrpc");
		break;
	default:
		echo "Error: Unknown option. Supported option: test|cluster|alarms-critical|alarms-warning\n";
		break;
}

// Pass to cmonapi or cmonrpc
function process_data ($cid, $arg, $method, $extra = 'warning') {
	if ( $method == "cmonapi" ){
		echo process_cmonapi($cid,$arg,$extra);
	}
	elseif ( $method == "cmonrpc" ){
		echo process_cmonrpc($cid,$arg,$extra);
	}
	else {
		echo "Unknown calling method. Please either specify cmonapi or cmonrpc.\n";
		exit (1);
	}
}

// Deprecated. Will be removed soon.
function call_cmonapi ( $cid, $arg ) {
	return shell_exec("./clustercontrol_api.sh -i {$cid} -r {$arg}");
}

// Call to RPC interface
function call_cmonrpc ( $cid, $arg ) {
	$ch = curl_init();

	if ( $arg == 'cluster-rpc' ) {
		$rpc_url = "http://" . RPC_HOST . ":" . RPC_PORT . "/0/clusters";

	        $data = http_build_query(array(
			'id'        => $cid,
	                'operation' => 'getHosts',
        	        'token'     => RPC_TOKEN
	        ));
	}
	elseif ( $arg == 'test-rpc' ) {
		$rpc_url = "http://" . RPC_HOST . ":" . RPC_PORT . "/0/clusters";
		$data = http_build_query(array(
                        'operation' => 'getHosts',
                        'token'     => RPC_TOKEN
                ));
	}
	elseif ( $arg == 'alarms' ) {
		$rpc_url = "http://" . RPC_HOST . ":" . RPC_PORT . "/0/clusters";
		$data = http_build_query(array(
			'cluster_id' => $cid,
			'operation'  => 'getClusterInfo',
			'token'      => RPC_TOKEN
		));
	}

        curl_setopt($ch, CURLOPT_URL, $rpc_url . '?' . $data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $result = curl_exec($ch);

	return $result;
}

// Process request via RPC interface
function process_cmonrpc ( $cid, $arg, $xopt ) {
	$ncid = explode(",",$cid);

	$arr = array();
	if ( $arg == 'test-rpc' ) {
		$arr = json_decode(call_cmonrpc(0,$arg));
		foreach ( $ncid as $cluster_id ) {
			$found = 0;
			$cl_id = (int) $cluster_id;
                        if ( $arr->requestStatus == "ok" ) {
                                foreach ( $arr->clusters as $cluster ) {
					if ( $cluster->id == $cl_id ) {
						echo "Cluster ID: " . $cluster->id . ", Cluster Name: " . $cluster->name . ", Cluster Type: " . $cluster->type . ", Cluster Status: " . $cluster->clusterStatus . "\n";
						$found = 1;
						break;
					}
					else {
						continue;
					}
				}
			}
			else {
				echo "Unable to contact ClusterControl RPC interface. Ensure token is correct and RPC interface is listening on " . RPC_HOST . " port " . RPC_PORT . "\n";
			}
			if ( $found == 0 ) {
				echo "Cluster ID $cl_id not found.\n";
			}
		}
	}
	elseif ( $arg == 'cluster-rpc' ) {
		// return 1 if ok, return 0 if critical, return 2 if degraded, return 3 if unknown/problem

		foreach ( $ncid as $cluster_id ) {
			$arr = json_decode(call_cmonrpc($cluster_id,$arg));
			if ( $arr->requestStatus == "ok" ) {
				if ( $arr->clusters[0]->clusterStatus == 'FAILURE' || $arr->clusters[0]->clusterStatus == 'CRITICAL' || $arr->clusters[0]->clusterStatus == 'STOPPED' || $arr->clusters[0]->clusterStatus == 'SHUTTING_DOWN' ) {
					$retval=0;
					break;
				}
				elseif ( $arr->clusters[0]->clusterStatus == 'DEGRADED' ) {
					$retval=2;
					break;
				}
				elseif ( $arr->clusters[0]->clusterStatus == 'ACTIVE' || $arr->clusters[0]->clusterStatus == 'STARTED' ) {
					$retval=1;
					continue;
				}
				else {
					$retval=3;
					break;
				}
			} else {
				print 'Unable to retrieve data from ClusterControl.';
			}
		}
		return $retval;
	}
	elseif ( $arg == 'alarms' ) {
		// return 0 if not ok, return 1 if ok, return 3 if unknown/problem

		foreach ( $ncid as $cluster_id ) {
			$arr = json_decode(call_cmonrpc($cluster_id,$arg));
			if ( $arr->requestStatus == "ok" ) {
				if ( $xopt == "critical" ) {
					if ( $arr->cluster->alarm_statistics->critical <> 0 ) {
						$retval=0;
						break;
					}
					else {
						$retval=1;
						continue;
					}

				}
				elseif ( $xopt == "warning" ) {
					if ( $arr->cluster->alarm_statistics->warning <> 0 ) {
						$retval=0;
						break;
					}
					else {
						$retval=1;
						continue;
					}
				}
				else {
					$retval=3;
					break;
				}
			}
		}
		return $retval;
	}
}

// Legacy cmonapi (deprecated, only keep it for reference and will be removed soon)
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
