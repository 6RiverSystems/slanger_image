# Slanger

Set of files to make Slanger Docker image and deploy it to GKE private registry

```
make # build image
make run # run container. Used to check that it is runable
make run_bash # start container and runs bush instead of slanger command
make push # publish image to GKI private registry
```

## Deployment

Write your deployment descriptor and run

```
kubectl create -f gke.yml
```
