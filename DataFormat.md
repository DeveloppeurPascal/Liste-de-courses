# Data processed in the project

The format and type of storage depends on the software and technology used. The data exchanged by the API must be in the format defined in the API and encoded in UTF-8.

Product labels are strings of up to 50 characters.
Quantities are positive, negative or null integers.
Customer IDs are strings of up to 50 characters (upper case letters, lower case letters, numbers).
Sequence numbers are integers starting at 0. A -1 value is possible if no sequence is recorded.

## Shopping

The shopping list contains products and their quantities.

It is an array. Each element of the array is an object with a "produit" property for the product name and a "qte" property for the quantity.

For example in JSON :
Races = [{"produit": "tomatoes", "qte":10},{"produit": "oranges", "qte":5}]

## Clients

The software that connects to the server are clients. They each have a unique ID assigned on request when they first connect.

Clients = [id, id, id]

## Modifications

The list of modifications contains products and variances used during updates.

Going from a quantity of 5 to a quantity of 10 results in a +5 difference.
Going from a quantity of 10 to a quantity of 7 results in a difference of -3.

When processing changes, the difference is added to the current quantity of the product concerned.

## Translation 

Page translated from french by [DeepL](https://www.deepl.com/translator).