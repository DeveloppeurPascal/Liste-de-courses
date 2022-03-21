<?php
	// GET /register
	require_once(__DIR__."/_protect.inc.php");
	require_once(__DIR__."/"._PROTECT."/db.inc.php");
	require_once(__DIR__."/"._PROTECT."/fonctions.inc.php");

	header('Access-Control-Allow-Origin: *');	
	header('Content-Type: application/json; charset=utf8');
		
	if ("GET" == $_SERVER["REQUEST_METHOD"]) {
		$result = new stdClass();
		$result->id = GenererID();
		$result->courses = getCourses();
		$result->sequence = getSequence();
		http_response_code(200);
		print(json_encode($result));
		exit;
	}
	else {
		http_response_code(404);
		exit;
	}
