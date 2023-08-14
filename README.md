# kafka-shenanigans
A repository where I test out a bunch of kafka related things. 

## Kubernetes
deploy a strimzi kafka cluster on Kubernetes
```
kubectl apply -f k8s/kafka-metrics-config.yaml
kubectl apply -f k8s/podmonitor.yaml
kubectl apply -f k8s/cluster.yaml
kubectl apply -f k8s/topic.yaml
kubectl apply -f connect/kafka-connect.yaml
```
get bootstrap endpoint
```
kubectl get service my-cluster-kafka-plain-bootstrap -o json | jq '.status.loadBalancer.ingress[0].hostname' -r
```