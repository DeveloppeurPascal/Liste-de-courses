# Using POSTMAN to test the API and the server

## GET method

When we send information in GET they are grouped in the URL of the recipient. On this side no surprise, the format received is unique and the programs concerned will know how to handle it.

In this case, in Postman, you must use the "Params" tab to list your parameters.

## POST method 

The problem arises when you want to send information in POST. Depending on the APIs and servers involved, the information may not be interpreted correctly.

In Postman it is the "Body" tab that you must use and it offers several solutions including "form-data" or "x-www-form-urlencoded".

The "form-data" encodes the parameters as a web form would with the "multipart/form-data" attribute used almost exclusively when you want to send files via a web form.

That's why it proposes to specify if each parameter is text or a file.

The "x-www-form-urlencoded" corresponds to a form without encoding type. This is the default format used by browsers.

This is the format you should use everywhere, unless a specific information tells you otherwise.

## Header parameters

In some cases you will need to add header parameters. This is usually the case for authentication keys.

You can use the "Authorizations" tab which will show you the list of fields generally required for different types of use and add your input to the header.

If you prefer to do it yourself because you find it faster, go directly to the "Headers" tab.

## Translation 

Page translated from french by [DeepL](https://www.deepl.com/translator).