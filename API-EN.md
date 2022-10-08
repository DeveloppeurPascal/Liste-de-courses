# API of the "shopping list" project

The proposed servers respond to the following http/s requests:

* GET /register
* POST /courses
* GET /courses

The URL of the server used must be indicated at the level of each client according to which server it must synchronize with. This address can point to a local version or to a "real" server depending on the needs.

When initializing a client, a registration with the server is necessary. It gets the shopping list in its current state and provides the identifier of each software used to send local updates to the server and to ask it for updates from other clients.

This identifier must be stored and used during the whole life of the application connected to a server.

If the connection is made to another server, the current client data must be dropped and a new registration will be made from the new server.

## Client registration on the server

The client queries the server for a unique ID when it first connects. It stores this ID and will use it in all its exchanges with the server.

The server also sends the current shopping list and the update sequence number from which to synchronize changes.

GET /register

Input parameters :
	none
	
Response:
	JSON object containing:
		- id: string, unique client ID, to be used for change synchronization
		- courses : JSON array containing {produit, qte} objects
		- sequence : sequence number of the last modification that gave this list
	http code 200

## Sending modifications

The client sends the modifications to be made on the shopping list to the server.

POST /courses

Input parameters :
	id => client ID
	chg => JSON array of changes made locally and not yet sent to server [{produit, qte},{produit, qte},{produit, qte}]

Response:
	http code 200 if ok
	http code 400 if input parameter problem

## Change loading

The client asks the server for the list of modifications that it has not yet processed locally.

GET /courses

Input parameters :
	id => client ID
	seq => number of the last processed modification

Response:
	a JSON object containing:
		- chg => JSON array of changes made by other clients [{produit, qte},{produit, qte},{produit, qte}]
		- sequence : sequence number of the last modification that gave this list
	code http 200
	code http 400 if input parameter problem

## Translation 

Page translated from french by [DeepL](https://www.deepl.com/translator).