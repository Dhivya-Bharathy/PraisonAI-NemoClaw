# PraisonAI-NemoClaw

Recipes for running [PraisonAI](https://github.com/MervinPraison/PraisonAI) agent teams inside
NVIDIA's OpenShell sandbox (the runtime behind [NemoClaw](https://github.com/NVIDIA/NemoClaw)),
on Nemotron models.

| Recipe | What it shows |
|---|---|
| [`contract-risk-review/`](contract-risk-review/) | Analyst → Policy-Checker → Writer review three synthetic vendor contracts and write `risk_report.md`. The sandbox policy allows only `inference.local`; an upload to pastebin and a write to `/etc/hosts` are blocked. A per-agent metrics table is printed at the end. |

Each recipe has its own README with prerequisites, bring-up, verification and teardown.

## Requirements

- Linux + Docker, OpenShell (pinned in each recipe), an NVIDIA API key for the inference route.
- PraisonAI with headless YAML support (`--trust`, `--metrics`, `output_file`, non-zero exit on failure).

## Relationship to NemoClaw

These recipes use plain OpenShell. `nemoclaw onboard --from` customises a *supported* agent's image
and doesn't onboard a new one. Native `--agent praisonai` support in NemoClaw needs an accepted
upstream proposal first.

## License

MIT
