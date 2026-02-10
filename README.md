# 🚀 Light Furry Games Platform
### Self-Service Multiplayer Infrastructure (Nakama + Agones + Kubernetes)

---

## 🎯 Mission

Enable game developers to spin up **complete multiplayer environments on demand**  
without learning Kubernetes, networking, or scaling.

If you can write a config file → you can run a game backend.

---

## 🧠 What the Platform Automatically Gives You

For every feature or developer environment:

✅ Nakama (auth, realtime, matchmaking)  
✅ CockroachDB  
✅ Prometheus metrics  
✅ Agones game server fleets  
✅ Automatic allocation  
✅ Player → server routing  
✅ Namespace isolation  
✅ Easy cleanup  

---

## 🏗 Architecture Overview

Players connect to Nakama.

When a match is found → Nakama asks Agones for a GameServer.

Agones returns IP/Port → Nakama notifies players.

Players connect to the dedicated server.

---

## 🔄 Runtime Flow

1. Player login  
2. Player joins matchmaker  
3. Match found  
4. Lua runtime calls Agones allocator  
5. Server assigned  
6. Players receive connection info  
7. Game starts 🎉  

---

## 🧩 Stack

| Component | Technology |
|-----------|-----------|
| Container Orchestration | Kubernetes |
| Game Server Scaling | Agones |
| Matchmaking / Gateway | Nakama |
| Database | CockroachDB |
| Metrics | Prometheus |
| Packaging | Helm |
| CI/CD | Jenkins |

---

---

# 👨‍💻 Developer Experience (VERY IMPORTANT)

Developers should not write Kubernetes manifests.

They create **ONE FILE**.

That’s it.

---

## Step 1 – Create a feature folder

```
bundles/<your-feature>/
```

Example:

```
bundles/rummy-v2/
```

---

## Step 2 – Add `config.yaml`

Example:

```yaml
# Feature Environment Configuration
name: feature-matchmaker

# Nakama Settings
nakama:
  version: dev4
  replicas: 1
 
# Agones Game Server Settings
gameserver:
  image: us-docker.pkg.dev/agones-images/examples/simple-game-server:0.41
  replicas: 3

matchmaker:
  min_players: 2
  max_players: 4
  tick_rate: 10
domainname: "lf.games.com" 
```

---

## Step 3 – Push to Git

Pipeline will handle everything else.

---

---

# 🤖 What CI/CD Does For You

When Jenkins runs:

✅ namespace created  
✅ cockroach installed  
✅ nakama installed  
✅ prometheus installed  
✅ lua scripts mounted 
✅ DNS ready   
✅ fleet created  
✅ scaling configured  
✅ services ready  

You receive a working multiplayer backend in minutes.

---

---

# 🧪 How To Test Locally

Port forward Nakama:

```bash
Point DNS to APK / Client
```

Run your client.

When match happens you will receive:

```
CONNECT TO: <gameserver-ip>:<port>
```

---

---

# 📁 Repository Layout

```
light-furry-games-platform/
│
├── infra-base/                 # Base helm chart shared by all environments
│
├── bundles/
│   ├── feature-a/
│   │   └── platform.yaml
│   ├── feature-b/
│   │   └── platform.yaml
│
├── jenkins/
│   └── pipeline.groovy
│
└── README.md
```

---

---

# 🧼 Destroy Environment

```bash
kubectl delete ns <namespace>
```

Everything is removed.

No leftovers.

---

---

# ⚡ What Agones Handles

- Replaces crashed servers  
- Keeps desired replica count  
- Provides IP/Port allocation  
- Works with dynamic scaling  

---

---

# 🛡 Isolation & Multi-Team Support

Each feature / team gets:

✔ dedicated namespace  
✔ dedicated Nakama  
✔ dedicated DB  
✔ dedicated fleets  

No cross impact.

---

---

# 📈 Why This Platform Matters

Without this:

❌ Devs depend on DevOps  
❌ Manual infra work  
❌ Slow testing  
❌ Hard scaling  

With this:

✅ self-service  
✅ fast iteration  
✅ repeatable  
✅ safe  
✅ production-like  

---

---

# 🚀 Future Enhancements

- Auto environment expiry  
- Web UI for provisioning  
- Cost tracking  
- Global allocation  
- Canary fleets  
- Observability packs  

---

---

# ❤️ Platform Philosophy

Developers should focus on **building games**.

The platform handles infrastructure.

---

