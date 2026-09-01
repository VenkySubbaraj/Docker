# k8s-fundamentals — Kubernetes from Beginner to Advanced

A hands-on, **learn-by-doing** curriculum that starts at *"what is a pod"* and
climbs to autoscaling, RBAC and ingress. Twelve lessons, each a folder with:

- a **heavily-commented manifest** (the code — every line explained inline), and
- a **README** that lists the concepts in the file, explains the *method*
  (how to think about it), gives commands to run, and ends with interview gotchas.

It uses only **public images** (nginx, busybox, http-echo) so there is **no
Docker build step**, and a **single-node cluster** so it's fast and light.

> New to the terminology? Read **[GLOSSARY.md](GLOSSARY.md)** first — every term
> defined in one line.
>
> Looking for a specific command? Jump to
> **[Command reference](#command-reference--every-command-used-in-this-track)** —
> every command the lessons use, grouped by task.
>
> Ready for advanced topics (deployment strategies, service mesh, node-failure
> drills, multi-zone affinity)? Those live in a separate advanced project,
> `k8s-mastery-lab` (a 5-node, multi-zone lab). If you have it, place it
> alongside this folder; if not, finish this track first — it's the right
> starting point.

---

## Concept-per-file index

**This is the map you asked for** — exactly which Kubernetes concepts live in
each file, in the order you should learn them.

| # | File | Concepts it teaches |
|---|---|---|
| 00 | `setup/kind-1node.yaml` | cluster definition, node, port mapping |
| 00 | `setup/setup.sh` | cluster bootstrap, metrics-server, ingress-nginx |
| 01 | `01-pods/pod.yaml` | **Pod**, container, image, labels, downward API, **init container**, **sidecar/multi-container pod**, emptyDir volume, desired state |
| 02 | `02-labels-namespaces/manifests.yaml` | **Namespace**, **labels**, **annotations**, equality & set-based **selectors** |
| 03 | `03-config-secrets/manifests.yaml` | **ConfigMap**, **Secret**, env-from-key, env-from-all, **mount config as files**, config/image separation |
| 04 | `04-deployments/deployment.yaml` | **Deployment**, **ReplicaSet**, replicas, **self-healing**, **rolling update**, maxSurge/maxUnavailable, **rollback** |
| 05 | `05-services-dns/manifests.yaml` | **Service**, **ClusterIP/NodePort/headless**, port vs targetPort, **cluster DNS**, **EndpointSlice**, load balancing |
| 06 | `06-storage/manifests.yaml` | **PVC/PV**, **StorageClass**, access modes, **StatefulSet**, volumeClaimTemplates, stable identity |
| 07 | `07-jobs-cron/manifests.yaml` | **Job**, completions/parallelism, backoffLimit, **CronJob**, schedule, concurrencyPolicy |
| 08 | `08-health-resources/manifests.yaml` | **requests/limits**, QoS, **startup/readiness/liveness probes**, **OOMKilled/exit 137** |
| 09 | `09-scheduling/manifests.yaml` | **scheduler filter/score**, **nodeSelector**, **node affinity**, **pod anti-affinity**, **taints/tolerations**, topologyKey |
| 10 | `10-autoscaling-hpa/manifests.yaml` | **HPA**, HPA formula, target utilisation, min/max replicas, scaling behavior |
| 11 | `11-rbac-security/manifests.yaml` | **ServiceAccount**, **Role/RoleBinding**, verbs/resources, **securityContext**, non-root, drop capabilities |
| 12 | `12-ingress/manifests.yaml` | **Ingress**, **ingress controller**, host/path routing, ingressClassName, pathType |

---

## Prerequisites

You need **Docker Desktop** (WSL2 engine, ≥4 GB RAM), **kubectl**, and **kind**.

Install on Windows (PowerShell):
```powershell
winget install -e --id Docker.DockerDesktop
winget install -e --id Kubernetes.kubectl
winget install -e --id Kubernetes.kind
```
Reboot, start Docker Desktop, and make sure "Use the WSL 2 based engine" is on.

Verify (in Git Bash):
```bash
docker version && kubectl version --client && kind version
```

**Windows gotchas:**
- Run the `.sh` scripts from **Git Bash**, not PowerShell.
- If a script errors with `\r: command not found`, it has CRLF endings — fix with
  `sed -i 's/\r$//' setup/setup.sh` or `git config --global core.autocrlf input`.
- `watch` doesn't exist in Git Bash; use
  `while true; do clear; <cmd>; sleep 2; done` instead.

---

## Quick start

```bash
cd /c/Users/VACWTB/Documents/k-projects/k8s-fundamentals
chmod +x setup/setup.sh
bash setup/setup.sh                 # single-node cluster + metrics-server + ingress
```

Then walk the lessons **in order**. For each one:
```bash
cat 01-pods/README.md               # read the concepts + method
kubectl apply -f 01-pods/pod.yaml   # apply the manifest
# ...follow the "Run it" commands in that README...
```

Teardown when finished:
```bash
kind delete cluster --name k8s-learn
```

---

## The learning path (what you'll be able to explain after each lesson)

| Lesson | After it, you can explain… |
|---|---|
| **01 Pods** | What a pod is, why containers share an IP, init vs sidecar |
| **02 Labels & Namespaces** | How k8s groups and scopes objects |
| **03 Config & Secrets** | How to configure an image without rebuilding it |
| **04 Deployments** | Self-healing, scaling, rolling updates, rollback |
| **05 Services & DNS** | How pods get a stable address and load balancing |
| **06 Storage** | How data survives pod death; when to use a StatefulSet |
| **07 Jobs & CronJobs** | How to run finite and scheduled work |
| **08 Health & Resources** | Probes, requests/limits, throttle vs OOMKill |
| **09 Scheduling** | How the scheduler places pods; affinity & taints |
| **10 Autoscaling** | How the HPA reacts to load, and its limits |
| **11 RBAC & Security** | Who-can-do-what, and hardening pods |
| **12 Ingress** | HTTP routing into the cluster |

---

## Where to go after this

```
k8s-fundamentals      <-- YOU ARE HERE: the objects, one at a time, single node
        │
        ▼  (once comfortable)
advanced topics       deployment strategies (blue-green/canary), HPA under real
                      load, multi-zone affinity, NODE FAILURE drills, Istio
                      service mesh, and interview Q&A
```

Start here. When every lesson below feels obvious, move on to the advanced
topics (the `k8s-mastery-lab` project, if you have it).

---

## Command reference — every command used in this track

The full list of commands the lessons ask you to run against the cluster,
grouped by what you're trying to *do*. The **L** column is the lesson the
command first appears in (`00` = `setup/`). Nothing here is new material — it's
a lookup table so you don't have to grep twelve READMEs.

### Cluster lifecycle (kind + kubectl context)

| Command | What it does | L |
|---|---|---|
| `docker version && kubectl version --client && kind version` | verify the three tools are installed | 00 |
| `bash setup/setup.sh` | create cluster + metrics-server + ingress-nginx in one shot | 00 |
| `kind create cluster --config setup/kind-1node.yaml --wait 120s` | create the single-node cluster | 00 |
| `kind delete cluster --name k8s-learn` | tear the whole thing down | 00 |
| `kubectl cluster-info` | API server + DNS endpoints — first sanity check | 00 |
| `kubectl get nodes` | are the nodes `Ready`? | 00 |
| `kubectl get nodes --show-labels` | built-in node labels (used by `nodeSelector`) | 09 |
| `kubectl config set-context --current --namespace=shop` | change the default namespace | 02 |
| `kubectl config set-context --current --namespace=default` | switch back | 02 |

### Apply and delete manifests

| Command | What it does | L |
|---|---|---|
| `kubectl apply -f <file>` | create-or-update from a manifest (declarative — the one you'll use 90% of the time) | 01 |
| `kubectl apply -f https://…/components.yaml` | install metrics-server from a remote manifest | 00 |
| `kubectl apply -f https://…/deploy.yaml` | install ingress-nginx (kind provider) from a remote manifest | 00 |
| `kubectl delete pod <name>` | delete one object | 01 |
| `kubectl delete pods -n shop -l app=frontend` | delete everything matching a label selector | 02 |
| `kubectl delete pod -l app=web --wait=false` | delete without blocking (watch self-healing happen) | 04 |
| `kubectl edit configmap app-config` | edit a live object in `$EDITOR` | 03 |
| `kubectl -n kube-system patch deployment metrics-server --type=json -p='[…]'` | surgical JSON patch (adds `--kubelet-insecure-tls`) | 00 |

### Inspect — the `get` family

| Command | What it does | L |
|---|---|---|
| `kubectl get pods` | the workhorse; check `STATUS` and `RESTARTS` | 01 |
| `kubectl get pods -o wide` | adds pod IP and node | 01 |
| `kubectl get pods --all-namespaces` | across every namespace | 02 |
| `kubectl get pods -w` | watch, streaming changes live | 04 |
| `kubectl get pods -l app=web` | filter by label | 02 |
| `kubectl get pods --show-labels` | show all labels as one column | 02 |
| `kubectl get pods -L app -L tier -L version` | show chosen labels as **columns** | 02 |
| `kubectl get deploy,rs,pods -l app=web` | several kinds at once — reveals the Deployment → ReplicaSet → Pod ownership chain | 04 |
| `kubectl get namespaces` | list namespaces | 02 |
| `kubectl get svc` | services + their ClusterIPs and ports | 05 |
| `kubectl get endpointslices` | the actual pod IPs behind each service | 05 |
| `kubectl get endpointslices -l kubernetes.io/service-name=hello -o wide` | endpoints for one service | 05 |
| `kubectl get pvc,pv` | claims and the volumes bound to them | 06 |
| `kubectl get statefulset,pods -l app=db -w` | watch ordered startup (`db-0` Ready *before* `db-1` starts) | 06 |
| `kubectl get job pi-batch` | `COMPLETIONS` column | 07 |
| `kubectl get cronjob heartbeat` | schedule + last-run time | 07 |
| `kubectl get hpa php-apache` | `TARGETS` = current vs target utilisation | 10 |
| `kubectl get sa,role,rolebinding` | the RBAC triangle | 11 |
| `kubectl get ingress demo-ingress` | hosts, paths, address | 12 |
| `kubectl get configmap app-config -o yaml` | full object as YAML | 03 |
| `kubectl get secret app-secret -o yaml` | note: values are base64, **not** encrypted | 03 |
| `kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' \| base64 -d` | pull one field out and decode it | 03 |

### Debug — describe, logs, exec, top

| Command | What it does | L |
|---|---|---|
| `kubectl describe pod <name>` | **read the `Events` section first** — it explains almost every failure | 01 |
| `kubectl describe pod impossible \| tail -6` | why a pod is stuck `Pending` (no node fits) | 09 |
| `kubectl describe pod oom-demo \| grep -A4 "Last State"` | proves `OOMKilled` / exit code 137 | 08 |
| `kubectl describe node \| grep -A8 "Allocated resources"` | how much CPU/memory is already requested on a node | 08 |
| `kubectl describe hpa php-apache \| tail -20` | the HPA's decision log | 10 |
| `kubectl logs <pod>` | container stdout | 01 |
| `kubectl logs <pod> -c <container>` | pick a container in a multi-container pod | 01 |
| `kubectl logs -l job-name=pi-batch --tail=1` | logs from all pods matching a selector | 07 |
| `kubectl logs job/manual-beat` | logs via the owning object | 07 |
| `kubectl exec -it <pod> -- sh` | interactive shell inside a container | 01 |
| `kubectl exec <pod> -- printenv LOG_LEVEL` | one-shot command; check an injected env var | 03 |
| `kubectl exec <pod> -- cat /etc/config/LOG_LEVEL` | check a mounted config **file** | 03 |
| `kubectl exec secure-pod -- id` | confirm the container is running non-root | 11 |
| `kubectl top pods` | live CPU/memory usage (needs metrics-server) | 08 |

### Networking / reach a workload

| Command | What it does | L |
|---|---|---|
| `kubectl port-forward pod/<pod> 8080:80` | tunnel a local port to a pod | 01 |
| `kubectl port-forward svc/hello 8080:80` | tunnel to a service (load-balances across pods) | 05 |
| `kubectl run client --rm -it --image=curlimages/curl:8.10.1 --restart=Never -- sh` | throwaway pod for in-cluster `curl` | 05 |
| `kubectl run dns --rm -it --image=busybox:1.36 --restart=Never -- nslookup db-0.db.default.svc.cluster.local` | resolve a headless-service pod DNS name | 06 |

### Labels, annotations, namespaces

| Command | What it does | L |
|---|---|---|
| `kubectl label pods -l app=frontend release=canary` | add a label to a whole group | 02 |
| `kubectl label node k8s-learn-control-plane disktype=ssd` | label a node so `nodeSelector`/affinity can target it | 09 |
| `kubectl annotate pod frontend-1 -n shop note="patched today"` | attach non-identifying metadata | 02 |
| `kubectl get pods -n shop -l 'app=frontend,version=v2'` | equality selector, AND-ed | 02 |
| `kubectl get pods -n shop -l 'version in (v1)'` | set-based selector | 02 |
| `kubectl get pods -n shop -l 'app!=backend'` | negated selector | 02 |

### Deployments — scale, update, roll back

| Command | What it does | L |
|---|---|---|
| `kubectl scale deploy/web --replicas=3` | change replica count imperatively | 04 |
| `kubectl set image deploy/web web=nginx:1.27` | trigger a rolling update | 04 |
| `kubectl rollout status deploy/web` | block until the roll finishes | 04 |
| `kubectl rollout history deploy/web` | list revisions + change-cause | 04 |
| `kubectl annotate deploy/web kubernetes.io/change-cause="bump to nginx 1.27" --overwrite` | make `rollout history` readable | 04 |
| `kubectl rollout undo deploy/web` | back to the previous revision | 04 |
| `kubectl rollout undo deploy/web --to-revision=1` | back to a specific revision | 04 |
| `kubectl rollout restart deploy/web` | re-roll all pods (e.g. to pick up changed config) | 04 |
| `kubectl scale statefulset db --replicas=1` | scale down a StatefulSet — PVCs are **kept** | 06 |

### Jobs and CronJobs

| Command | What it does | L |
|---|---|---|
| `kubectl get pods -l job-name=pi-batch -w` | watch workers run to `Completed` | 07 |
| `kubectl get jobs -w` | a new Job appears each time the CronJob fires | 07 |
| `kubectl create job --from=cronjob/heartbeat manual-beat` | fire a CronJob now, on demand | 07 |

### Scheduling and autoscaling

| Command | What it does | L |
|---|---|---|
| `kubectl get pods -l demo=sched -o wide` | which node each pod landed on | 09 |
| `kubectl run impossible --image=nginx:1.27-alpine --overrides='{"spec":{"nodeSelector":{"disktype":"nvme-nonexistent"}}}'` | deliberately unschedulable pod, to read the scheduler's complaint | 09 |
| `kubectl run -it --rm load --image=busybox:1.36 --restart=Never -- sh -c "while true; do wget -q -O- http://php-apache; done"` | generate CPU load so the HPA scales up | 10 |

### RBAC — prove permissions

| Command | What it does | L |
|---|---|---|
| `kubectl auth can-i list pods --as=$SA` | ask the API server directly (`yes`/`no`) | 11 |
| `kubectl auth can-i get pods/log --as=$SA` | subresources are granted separately | 11 |
| `kubectl auth can-i list secrets --as=$SA` | expect `no` — resource not in the Role | 11 |
| `kubectl auth can-i delete pods --as=$SA` | expect `no` — verb not in the Role | 11 |
| `kubectl auth can-i create deployments --as=$SA` | expect `no` — different API group | 11 |

### Git Bash / Windows notes

`watch` doesn't exist in Git Bash — use a loop instead of `watch kubectl get pods`:

```bash
while true; do clear; kubectl get pods; sleep 2; done
```

Other conveniences worth knowing:

```bash
kubectl get pods -w                       # built-in watch, no external tool needed
kubectl api-resources                     # every kind, its short name and API group
kubectl explain deployment.spec.strategy  # field-level docs straight from the API server
kubectl get events --sort-by=.lastTimestamp   # cluster-wide, most recent last
kubectl apply -f <file> --dry-run=server  # validate against the API without applying
```

---

## Project structure

```
k8s-fundamentals/
├── README.md                 <- this file (concept-per-file index)
├── GLOSSARY.md               <- one-line definition of every term
├── setup/
│   ├── kind-1node.yaml
│   └── setup.sh
├── 01-pods/                  {pod.yaml, README.md}
├── 02-labels-namespaces/     {manifests.yaml, README.md}
├── 03-config-secrets/        {manifests.yaml, README.md}
├── 04-deployments/           {deployment.yaml, README.md}
├── 05-services-dns/          {manifests.yaml, README.md}
├── 06-storage/               {manifests.yaml, README.md}
├── 07-jobs-cron/             {manifests.yaml, README.md}
├── 08-health-resources/      {manifests.yaml, README.md}
├── 09-scheduling/            {manifests.yaml, README.md}
├── 10-autoscaling-hpa/       {manifests.yaml, README.md}
├── 11-rbac-security/         {manifests.yaml, README.md}
└── 12-ingress/               {manifests.yaml, README.md}
```

Every `manifests.yaml` is commented line-by-line; every `README.md` opens with a
**"Concepts in this lesson"** table so you always know what a file covers.
