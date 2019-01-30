
## Using the container
```
docker run -it --init -p 8888:8888 \
		-e LOCAL_UID=$(id -u $USER) \
		-v .:/home/user boecklic/jupylab:latest
```

