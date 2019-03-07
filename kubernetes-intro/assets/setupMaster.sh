#!/usr/bin/env bash
kubeadm init --kubernetes-version $(kubeadm version -o short)
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f kube-flannel.yaml
