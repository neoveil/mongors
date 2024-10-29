# mongors

a ready to use mongo replica set image for development purposes. **this is not production ready!**

# running

for a `docker-compose` example, see [this](https://github.com/neoveil/docker-composes/blob/main/mongo/docker-compose.yml), or else run:

``` shell
docker run -d -p 27017:27017 -p 27018:27018 -p 27019:27019 neoveil/mongors
```
