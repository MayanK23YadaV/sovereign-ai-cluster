# Contributing to Sovereign AI Cluster

First off, thank you for considering contributing to Sovereign AI Cluster! It's people like you that make the open-source community such a fantastic place to learn, inspire, and create.

## Where to Start

If you are looking to contribute, we highly encourage PRs that address the following core areas of the architecture:

1. **Network Latency Optimizations:** Implementations for MPI, RoCE (RDMA), or BitTorrent-style P2P model distribution protocols to bypass 1Gbps bottlenecks.
2. **Declarative Infrastructure:** Migrations from mutable Ansible states to immutable NixOS configurations.
3. **Observability:** Prometheus/Grafana dashboards for tracking cluster health and tokens/sec.
4. **API Standardization:** Compatibility layers for OpenAI endpoints.

## How to Submit a Pull Request

1. **Fork the repository** and clone it locally.
2. **Create a branch** for your edits (`git checkout -b feature/amazing-feature`).
3. **Commit your changes** with descriptive commit messages.
4. **Push your branch** to your fork.
5. **Open a Pull Request** against the `main` branch of this repository.

### Guidelines
* Please ensure your scripts do not contain hardcoded IPs, passwords, or proprietary university/lab information.
* Bash scripts must use `set -e` where appropriate.
* Ansible playbooks should be idempotent (running them twice should not break the system).

Thank you for helping us build the future of decentralized, sovereign artificial intelligence!
