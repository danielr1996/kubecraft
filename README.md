![kubecraft logo](./docs/logo.jpg)

# kubecraft
crafting kubernetes with a single command

## Goal

> This is work in progress project which will gradually evolve over time. In this section I will explain what my goal is,
> but please be aware that this goal is still far away. However, I want to continously improve this project and start with
> what brings the most benefit. 

The goal is to create a simple to use singlecommand kubernetes setup. To achieve this I'm heavily relying on automation, 
namely the ClusterAPI specification. The config is also specified in a single git repository, making it easy to completely
teardown a cluster and recreate it.

## Process
- create a temporary kind cluster
- bootstrap a management cluster
- move capi to management cluster
- delete temporary kind cluster

## Requirements

- kubectl
- helm
- kind to bootstrap a temporary cluster
- hetzner cloud account
