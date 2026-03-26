# Root-First Folder Layout for Spark

This is the recommended host filesystem layout when starting from `/` on DGX Spark.

## Target Layout

```text
/
|- opt/
|  |- gracey/
|     |- (git repo root)
|     |- configs/
|     |- docs/
|     |- interfaces/
|     |- platform/
|     |- scripts/
|     |- ...
|
|- var/
|  |- log/
|     |- gracey/
|
|- tmp/
|  |- gracey-bootstrap/
```

## Why this layout

- `/opt/gracey` keeps application code in a standard location for managed services.
- `/var/log/gracey` centralizes logs for API, runtime workers, and systemd services.
- `/tmp/gracey-bootstrap` gives a safe temporary workspace for setup diagnostics.

## Ownership Model

Recommended owner for `/opt/gracey` and `/var/log/gracey`:

- The operator user that will run Gracey services (for example `ubuntu`).

Use group ownership if multiple operators need access.

## Network Identity

Use node hostname and internal network identity consistently:

- Hostname: `promaxgb10-4afb.local`
- Tailscale: enabled
- NVIDIA Sync: enabled

Keep these values in `configs/gracey_stack.yaml` and local `.env`.

## Bootstrap Script

Use the provided script from `/` as root:

```bash
cd /
sudo bash /opt/gracey/scripts/bootstrap_gracey_spark.sh \
  --repo-url <your-repo-url> \
  --install-dir /opt/gracey \
  --node-hostname promaxgb10-4afb.local \
  --install-nemoclaw
```

If the repo is not yet at `/opt/gracey`, first clone it to any temporary path and run:

```bash
sudo bash <temp-repo-path>/scripts/bootstrap_gracey_spark.sh --repo-url <your-repo-url>
```
