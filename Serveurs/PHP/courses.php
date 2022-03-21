<?php
	// GET /courses
	// POST /courses
	require_once(__DIR__."/_protect.inc.php");
	require_once(__DIR__."/"._PROTECT."/db.inc.php");
	require_once(__DIR__."/"._PROTECT."/fonctions.inc.php");

	header('Access-Control-Allow-Origin: *');	
	header('Content-Type: application/json; charset=utf8');

	if ("GET" == $_SERVER["REQUEST_METHOD"]) {
		if (isset($_GET["id"]) && isset($_GET["seq"])) {
			$id = $_GET["id"];
			$seqS = $_GET["seq"];
			if (empty($id) || empty($seqS)) {
				http_response_code(400);
				exit;
			}
			$seq = intval($seqS);
			// TODO : vérifier éventuellement que ID client existe
			$result = new stdClass();
			$result->chg = getModifs($id, $seq);
			$result->sequence = getSequence();
			http_response_code(200);
			print(json_encode($result));
			exit;
		}
		else {
			http_response_code(400);
			exit;
		}
	}
	else if ("POST" == $_SERVER["REQUEST_METHOD"]) {
		if (isset($_POST["id"]) && isset($_POST["chg"])) {
			$id = $_POST["id"];
			$chgS = $_POST["chg"];
			if (empty($id) || empty($chgS)) {
				http_response_code(400);
				exit;
			}
			$qry = $db->prepare("select * from clients where idclient=:ci");
			$qry->execute(array(":ci"=>$id));
			if (false !== ($res = $qry->fetch())) {
				// ID client existant
				$chg = json_decode($chgS);
				if (is_array($chg)) {
					foreach ($chg as $obj) {
						if (is_object($obj)) {
							$qry = $db->prepare("insert into modifs (idclient, produit, quantite) values (:ci, :p, :q)");
							$qry->execute(array(":ci"=>$id,":p"=>$obj->produit,":q"=>$obj->qte));
							$qry = $db->prepare("select count(*) from courses where produit=:p");
							$qry->execute(array(":p"=>$obj->produit));
							if ((false !== ($res = $qry->fetch(PDO::FETCH_NUM))) && ($res[0] > 0)) {
								$qry = $db->prepare("update courses set quantite=quantite+:q where produit=:p");
								$qry->execute(array(":p"=>$obj->produit,":q"=>$obj->qte));
							}
							else {
								$qry = $db->prepare("insert into courses (produit, quantite) values (:p, :q)");
								$qry->execute(array(":p"=>$obj->produit,":q"=>$obj->qte));
							}
						}
					}
					http_response_code(200);
					exit;
				}
				else {
					http_response_code(400);
					exit;
				}
			}
			else {
				// ID client inconnu
				http_response_code(400);
				exit;
			}
		}
		else {
			http_response_code(400);
			exit;
		}
	}
	else {
		http_response_code(404);
		exit;
	}