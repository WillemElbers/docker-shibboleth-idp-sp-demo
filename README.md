## Building the image 

[![Build Status](https://travis-ci.org/WillemElbers/docker-shibboleth-idp-sp-demo.svg?branch=master)](https://travis-ci.org/WillemElbers/docker-shibboleth-idp-sp-demo)

In order to build the docker image run the following command:

```
make
```

## Running the image


```
docker run -ti --rm -p 80:80 -p 443:443 shibboleth/sp-idp-demo:<version>
```

## ToDo's

* Enable checkAdress=true for the session handler in shibboleth.xml.
* Properly configure attribute scope so that we can enable SP attribute filtering for eppn and targeted-id in attribute-policy.xml. See: [Removed-value-at-position-0-of-attribute](http://shibboleth.1660669.n2.nabble.com/Removed-value-at-position-0-of-attribute-td7588463.html).