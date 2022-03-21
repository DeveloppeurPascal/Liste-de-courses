<?php
	function GenererID() {
		global $db;
		
		$lettres = "0123456789abcdefghijklmnopqrstuvwxyzAZERTYUIOPMLKJHGFDSQWXCVBN";
		$result = "";
		for ($i = 0; $i < 49; $i++) {
			$result .= substr($lettres, mt_rand(0, strlen($lettres)-1), 1);
		}
		
		$qry = $db->prepare("select count(*) from clients where idclient=:ci");
		$qry->execute(array(":ci"=>$result));
		if ((false !== ($res = $qry->fetch(PDO::FETCH_NUM))) && ($res[0] > 0)) {
			return GenererID();
		}
		else {
			$qry = $db->prepare("insert into clients (idclient) values (:ci)");
			$qry->execute(array(":ci"=>$result));
			return $result;
		}
	}
	
	function getCourses() {
		global $db;
		
		$result =array();
		
		//$qry = $db->prepare("select * from courses order by produit");
		$qry = $db->prepare("select * from courses");
		$qry->execute();
		while (false !== ($res = $qry->fetch(PDO::FETCH_OBJ))) {
			$obj = new stdClass();
			$obj->produit = $res->produit;
			$obj->qte = $res->quantite;
			$result[] = $obj;
		}
		return $result;
	}
	
	function getSequence() {
		global $db;
		
		$qry = $db->prepare("select sequence from modifs order by sequence desc limit 0,1");
		$qry->execute();
		if (false !== ($res = $qry->fetch(PDO::FETCH_OBJ))) {
			return $res->sequence;
		}
		else {
			return -1;
		}
	}
	
	function getModifs($ClientID, $Sequence) {
		global $db;
		
		$result =array();
		
		$qry = $db->prepare("select * from modifs where (sequence > :s) and (idclient <> :ci)");
		$qry->execute(array(":ci"=>$ClientID,":s"=>$Sequence));
		while (false !== ($res = $qry->fetch(PDO::FETCH_OBJ))) {
			$obj = new stdClass();
			$obj->produit = $res->produit;
			$obj->qte = $res->quantite;
			$result[] = $obj;
		}
		return $result;
	}
