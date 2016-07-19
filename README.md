## Building the image

In order to build the docker image run the following command:

```
make
```

## Running the image


```
docker run -ti --rm -p 80:80 -p 443:443 shibboleth/sp-idp-demo:<version>
```