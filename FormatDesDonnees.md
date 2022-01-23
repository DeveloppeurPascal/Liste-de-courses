# Données traitées dans le projet

Le format et le type de stockage dépend du logiciel et de la technologie utilisée. Les données échangées par l'API doivent être dans le format défini dans l'API et encodées en UTF-8.

Les libellés de produits sont des chaînes de caractères de 50 caractères maximum.
Les quantités sont des entiers positifs, négatifs ou nuls.
Les ID clients sont des chaînes de caractères de 50 caractères maximum.
Les numéros de séquence sont des entiers commençant à 0. Une valeur -1 est possible si aucune séquence n'est enregistrée.

## Courses

La liste de courses contient des produits et leurs quantités.

C'est un tableau. Chaque élément du tableau est un objet avec une propriété "produit" et une propriété "quantite".

Par exemple en JSON :
Courses = [{"produit":"tomates","quantite":10},{"produit":"oranges","quantite":5}]

## Clients

Les logiciels qui se connectent au serveur sont des clients. Ils ont chacun un ID unique attribué sur demande lors de leur première connexion.

Clients = [id, id, id]

## Modifications

La liste des modifications contient des produits et les écarts utilisés lors des mises à jour.

Passer d'une quantité 5 à une quantité 10 entraîne un écart de +5.
Passer d'une quantité 10 à une quantité 7 entraîne un écart de -3.

Lors du traitement des modifications, l'écart est ajouté à la quantité actuelle du produit concerné.
