# Spyglass

**Spyglass is a self-hosted Kubernetes dashboard** for observing and managing
clusters from a single web UI. Observe nodes, pods, deployments, and services;
stream pod logs live; create and edit resources with cluster-aware visual
builders; expose an app end-to-end (Deployment → Service → Certificate → Gateway
→ Route) in one guided flow; and get an at-a-glance overview of endpoint health
and capacity. The whole app ships as **one container** — a Vue SPA embedded in a
small Go binary that runs inside your cluster.

> Spyglass is proprietary, commercial software. See the [EULA](LICENSE). It is
> **freemium**: free for small clusters, with paid tiers for larger ones — and
> it always verifies its license **offline** (no phone-home).

This repository is the **public distribution** for Spyglass — the Helm chart,
release binaries, and container image live here. The source is not public.

- 🌐 Website & sign-up: **https://spyglass.sh**
- 💳 Pricing & trials: **https://spyglass.sh/pricing**
- 📦 Container image: `ghcr.io/unishsys/spyglass`
- ⎈ Helm chart (OCI): `oci://ghcr.io/unishsys/charts/spyglass`

---

## Editions

Spyglass is gated by **cluster size (node count)**. **Viewing is always free,
with no key.** *Making changes* (create/edit/delete) requires a license — a free
Community key, or a trial/paid key. Beyond your node cap, changes pause until you
upgrade; the dashboard always stays fully readable.

| Edition | Node limit | How to get it |
| --- | --- | --- |
| **Community** | up to 10 nodes | free — [create an account](https://spyglass.sh) for a free key |
| **Trial** | unlimited | free for 14 days — [start a trial](https://spyglass.sh/pricing) |
| **Pro** | up to 50 nodes | self-serve subscription |
| **Enterprise** | unlimited / multi-cluster | + SSO, RBAC, audit, support — [contact us](https://spyglass.sh/pricing) |

## 1. Register & get a license key

1. Create a free account at **https://spyglass.sh**. A **Community** key is
   issued to you automatically.
2. For unlimited evaluation, [start a 14-day trial](https://spyglass.sh/pricing);
   to subscribe, pick a plan at checkout.
3. Your current key (and a personalized install guide) is always available on
   your **dashboard** at https://spyglass.sh. Keys are renewed/extended
   automatically while your subscription is active.

You can install and **view** your cluster without any key — you only need one to
make changes.

## 2. Install

### Helm (recommended)

The chart is published as an **OCI artifact** on GHCR. Helm 3.8+ is required.

```sh
# Installs the latest stable release. Defaults to secure token auth and
# generates an auth token for you.
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass \
  --namespace spyglass --create-namespace
```

Pin a specific version (recommended for production), or install a pre-release:

```sh
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass \
  --version 1.0.1 --namespace spyglass --create-namespace

# pre-releases (e.g. betas) must be requested by exact version:
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass \
  --version 1.0.0-beta --namespace spyglass --create-namespace
```

Read your auth token and reach the UI:

```sh
kubectl -n spyglass get secret spyglass-secrets -o jsonpath='{.data.AUTH_TOKEN}' | base64 -d ; echo
kubectl -n spyglass port-forward svc/spyglass 8081:8081   # then open http://localhost:8081/
```

To expose it publicly, enable the Ingress and TLS:

```sh
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass --reuse-values \
  --set ingress.enabled=true --set ingress.className=nginx \
  --set ingress.host=spyglass.example.com \
  --set ingress.tls.enabled=true --set ingress.tls.secretName=spyglass-tls
```

**Apply your license:**

```sh
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass --reuse-values \
  --set license.key='<YOUR_KEY>'
# or reference a Secret that holds a LICENSE_KEY key:
helm upgrade --install spyglass oci://ghcr.io/unishsys/charts/spyglass --reuse-values \
  --set license.existingSecret=my-license
```

The current tier, trial countdown, and node usage are shown in the dashboard's
license banner.

> **Security:** Spyglass has cluster-wide access — treat dashboard access as
> cluster access. Don't run `auth.mode=none` on shared/exposed clusters, and
> serve it over HTTPS.

### Container image

The image runs inside Kubernetes via the Helm chart above (`incluster` mode). To
point it at a cluster from your workstation, run it in `remotecluster` mode with
your kubeconfig mounted:

```sh
docker run --rm -p 8081:8081 \
  -v "$HOME/.kube/config:/home/nonroot/.kube/config:ro" \
  ghcr.io/unishsys/spyglass:1.0.1 remotecluster
# then open http://localhost:8081/  (AUTH_MODE defaults to none in this mode)
```

Images are multi-arch (`linux/amd64`, `linux/arm64`), ship an SBOM + provenance,
and are **cosign-signed** (keyless). Verify:

```sh
cosign verify ghcr.io/unishsys/spyglass:1.0.1 \
  --certificate-identity-regexp 'https://github.com/unishsys/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

### Standalone binary

Download the binary for your OS/arch from the
[latest release](https://github.com/unishsys/spyglass/releases/latest), verify it
against `SHA256SUMS`, then run it against your kubeconfig:

```sh
# macOS (Apple Silicon) example
curl -sSLO https://github.com/unishsys/spyglass/releases/download/v1.0.1/spyglass-darwin-arm64
curl -sSLO https://github.com/unishsys/spyglass/releases/download/v1.0.1/SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing   # verify
chmod +x spyglass-darwin-arm64
./spyglass-darwin-arm64 remotecluster           # serves the UI on :8081
```

Binaries are published for:

| OS | Architectures |
| --- | --- |
| macOS | `amd64` (Intel), `arm64` (Apple Silicon) |
| Linux | `amd64`, `arm64` |
| Windows | `amd64` (`.exe`) |

## 3. Usage

- **Run modes:** `incluster` (inside a pod, uses the ServiceAccount — what the
  Helm chart runs) or `remotecluster` (uses your local `~/.kube/config`).
- **Authentication:** the Helm chart defaults to `token` mode and generates a
  stable token. Read it from the `spyglass-secrets` Secret (above). For a local
  binary, auth defaults to `none`.
- **License:** paste your key (Helm `license.key`, or `LICENSE_KEY` env). Empty =
  Community tier. Verified offline; works in air-gapped clusters.
- **Optional integrations** degrade gracefully when absent: metrics-server
  (CPU/memory), Gateway API, cert-manager / external-dns (the domain → DNS → TLS
  → gateway chain), and Ollama (the in-app AI assistant).

### Common configuration

Set these via Helm (`--set`) or as environment variables on the container:

| Variable / Helm value | Default | Purpose |
| --- | --- | --- |
| `auth.mode` / `AUTH_MODE` | `token` (chart) | `none`, `token`, or `proxy-header`. |
| `auth.token` / `AUTH_TOKEN` | _(generated)_ | Static bearer token for `token` mode. |
| `license.key` / `LICENSE_KEY` | _(unset)_ | Signed license token. Empty = Community. |
| `ingress.*` | disabled | Expose the UI via an Ingress + TLS. |
| `telemetryDisabled` / `TELEMETRY_DISABLED` | `false` | Disable the optional anonymous usage ping. |
| `OLLAMA_URL` | `http://localhost:11434` | Optional AI (Ollama) endpoint. |

See `helm show values oci://ghcr.io/unishsys/charts/spyglass` for the full list.

## Support & legal

- Docs & guides: https://spyglass.sh
- Support: support@spyglass.sh
- License: [EULA](LICENSE) · Privacy & Terms: https://spyglass.sh
