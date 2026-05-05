# Sovereign AI Lab — Deployment & Progress Log

## 1. Our Progress & How We Built It
We successfully transformed a collection of individual desktop computers into a unified, distributed AI supercomputer. We shifted away from the cumbersome "Clonezilla USB" method and built a fully automated, scalable Swarm architecture.

**Key Achievements:**
*   **Dynamic Network Discovery:** We built `discover_nodes.sh`, which uses `nmap` to scan the local subnet, automatically detects fresh Linux Mint installations, injects SSH keys using `sshpass`, and dynamically writes an Ansible inventory.
*   **Ansible Orchestration:** We engineered `cluster_init.yml`, a master playbook that automatically:
    *   Assigns unique hostnames (`node02`, `node03`, etc.).
    *   Locks CPU governors to `performance` mode for maximum AI throughput.
    *   Installs dependencies and `btop` (configured to 100ms refresh rate).
    *   Disables all GUI sleep timers and system-level hibernation protocols.
    *   Pushes the compiled `llama.cpp` AI stack from the Head Node to the workers via `rsync`.
    *   Deploys the `llama-rpc` engine as a permanent background service.
*   **Visual Identity:** We added custom colored terminal prompts (🔴 Red for Head, 🟢 Green for Workers) and massive ASCII art MOTD banners so the physical screens are instantly recognizable.
*   **Dual-Boot Automation:** We added logic to dynamically find the unique Windows Boot Manager UUID on every machine and permanently set it as the default GRUB priority.

## 2. Hurdles & Challenges Overcome
*   **The Fortinet Captive Portal:** The campus network required a web login, which headless nodes couldn't complete. We bypassed this elegantly: we realized only the Head Node needed the internet. The worker nodes just needed local network access, and the Head Node pushed all the necessary software to them offline.
*   **The "Clonezilla Identity Theft":** This was our craziest hurdle. Because the very first worker node was cloned from the Head Node, it woke up with the Head Node's Cloudflare Tunnel (`cloudflared`) running. Cloudflare seamlessly routed our SSH connection to the Clone without us knowing. We accidentally ran the deployment from the Clone, which proceeded to discover the *Original* Head Node, assimilate it as a worker, and wipe its tunnel credentials! We resolved this by physically disabling the tunnel, renaming the Clone, and officially anointing the Clone as the new Head Node.
*   **Hardware UUID Mismatches:** We couldn't hardcode the Windows boot priority because every manually installed machine has a different hard drive ID. We overcame this by using Ansible to execute an `awk`/`grep` search to dynamically locate the exact boot string on a per-machine basis.

## 3. What We Learned
*   **Distributed Memory Efficiency:** When we ran the `DeepSeek-R1-Distill-Qwen-7B` model across the 6 workers, we proved that the `llama.cpp` RPC backend is incredibly efficient. The 4.4GB model was seamlessly sliced up over the network. Each worker node utilized exactly ~2.2GB of RAM (model chunks + context computation space), while the Head Node used a mere 500MB to orchestrate the entire Swarm.
*   **Reasoning Models Stress the Swarm:** We learned that models with a `<think>` token (like DeepSeek) are the ultimate stress test for the cluster. Because they generate massive internal chains-of-thought before answering, they force the RPC nodes to constantly compute matrix multiplications, pegging the CPUs at 100%.

## 4. How We Will Work Next
*   **Scaling to 30 Nodes:** The architecture is now flawless. Your next step is to continue plugging in the remaining 23 computers, installing Linux Mint, and hooking them up to the network. We will simply run `discover_nodes.sh` and the Ansible playbook to assimilate them in batches. 
*   **The ChatGPT Web UI:** We successfully deployed `llama-server` in the background of the Head Node. Moving forward, you will operate the Swarm securely from your Windows machine by running `ssh -L 8080:localhost:8080 node01` and opening `http://localhost:8080` in your browser.
*   **Pushing the Limits:** Once the 30 nodes are connected (providing over 480 CPU cores), we will abandon 7B models and test massive 70B+ parameter models (like Llama-3-70B) that would be physically impossible to fit in the RAM or compute power of a single machine.
