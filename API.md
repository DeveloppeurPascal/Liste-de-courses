# API du projet "liste de courses"

Les serveurs proposés répondent aux demandes http/s suivantes :
* GET /register
* POST /courses
* GET /courses

L'URL du serveur utilisé doit être indiquée au niveau des clients. Cette adresse peut pointer sur une version locale ou sur un "vrai" serveur selon les besoins.

Lors de l'initialisation d'un client, une inscription auprès du serveur est nécessaire. Elle renseigne la liste de courses dans son état actuel et fournit l'identifiant de chaque logiciel qui sera nécessaire pour envoyer les mises à jour locales vers le serveur et lui demander les mises à jour provenant des autres clients.

Cet identifiant doit être stocké et utilisé durant toute la vie de l'application connectée à un serveur.

Si la connexion est effectuée vers un autre serveur, les données actuelles du clients doivent être abandonnées et un nouvel enregistrement sera fait depuis le nouveau serveur.

## Enregistrement du client sur le serveur

Le client interroge le serveur pour obtenir un ID unique lors de sa première connexion. Il stocke cet ID et l'utilisera dans tous ses échanges avec le serveur.

Le serveur transmets également la liste de courses actuelle et le numéro de séquence des mises à jours à partir duquel il faudra synchroniser les modifications.

GET /register

Paramètres en entrée :
	aucun
	
Sortie :
	objet JSON contenant :
		- id : chaîne de caractères, ID unique du client, à utiliser pour les synchronisations de modifications
		- courses : tableau JSON concenant des objets {produit, qte}
		- sequence : numéro de séquence de la dernière modification ayant donné cette liste
	code http 200

## Envoi de modifications

Le client transmets les modifications à effectuer sur la liste de courses au serveur.

POST /courses

Paramètres en entrée :
	id => ID du client
	chg => tableau JSON des modifications effectuées en local et pas encore envoyées au serveur [{produit, qte},{produit, qte},{produit, qte}]

Sortie :
	code http 200 si ok
	code http 400 si problème de paramètre d'entrée

## Chargement de modification

Le client demande au serveur la liste des modification qu'il n'a pas encore traitées localement.

GET /courses

Paramètres en entrée :
	id => ID du client
	seq => numéro de la dernière modification traitée

Sortie :
	un object JSON contenant :
		- chg => tableau JSON des modifications effectuées par les autres clients [{produit, qte},{produit, qte},{produit, qte}]
		- sequence : numéro de séquence de la dernière modification ayant donné cette liste
	code http 200
	code http 400 si problème de paramètre d'entrée
