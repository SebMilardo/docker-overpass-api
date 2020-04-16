# docker-overpass-api

OpenStreetMap Docker for [Overpass API](http://wiki.openstreetmap.org/wiki/Overpass_API).

## Building the Docker image

Change the boundary of the research area in bbox.csv then build the image

```
docker build -t overpass:local .
```

## Running the Docker image

`docker run -d -p 8081:8081 overpass:local`

