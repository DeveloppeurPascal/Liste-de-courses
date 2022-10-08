# Utilisation de POSTMAN pour tester l'API et le serveur

## Méthode GET

Lorsqu'on envoie des informations en GET elles sont regroupées dans l'URL du destinataire. De ce côté pas de surprise, le format reçu est unique et les programmes concernés sauront le gérer.

Dans ce cas, dans Postman, vous devez utiliser l'onglet "Params" pour lister vos paramètres.

## Méthode POST 

Le problème se pose en revanche quand vous désirez envoyer des informations en POST. Selon les API et les serveurs concernés il est possible que l'information ne soit pas interprétée correctement.

Dans Postman c'est l'onglet "Body" qu'il faut utiliser et il vous propose plusieurs solutions dont "form-data" ou "x-www-form-urlencoded".

Le "form-data" encode les paramètres comme le ferait un formulaire web avec l'attribut "multipart/form-data" utilisé quasiment uniquement lorsqu'on veut envoyer des fichiers par l'intermédiaire d'un formulaire web.

C'est pour cette raison qu'il propose de spécifier si chaque paramètre est du texte ou un fichier.

Le "x-www-form-urlencoded" correspond à un formulaire sans type d'encodage. C'est le format par défaut utilisé par les navigateurs.

C'est lui que vous devez utiliser partout, sauf si une information spécifique vous dit le contraire.

## Les paramètres d'entête

Dans certains cas vous devrez ajouter des paramètres d'entête. C'est en général le cas pour les clés d'authentification.

Vous pouvez vous aider de l'onglet "Authorizations" qui vous proposera la liste de champs généralement demandés selon les types d'utilisation et ajoutera votre saisie à l'entête.

Si vous préférez le faire vous-même car vous trouvez ça plus rapide, passez directement dans l'onglet "Headers".
