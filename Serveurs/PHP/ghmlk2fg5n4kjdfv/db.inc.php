<?php
	require_once(__DIR__."/_config.inc.php");
	try {
		$db = new PDO("mysql:dbname=".DB_NAME.";host=".DB_HOST.";charset=UTF8", DB_USER, DB_PWD, array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8'));
	}
	catch (PDOException $e) {
		http_response_code(503);
		exit;
	}

	if (! is_object($db)) {
		http_response_code(503);
		exit;
	}