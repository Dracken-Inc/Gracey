# Gracey Setup Checklist

Use this checklist with `docs/setup_gracey_playbook.md`.

## Pre-Flight

- [ ] Repo cloned
- [ ] `secrets/GraYc.txt` present and unchanged
- [ ] Required config files present

## Track A - No-Hardware

- [ ] Start mock API
- [ ] `GET /healthz` returns `status: ok`
- [ ] `assistants_count` is `4`
- [ ] `/v1/route` returns role, assistant, lane, classifier, confidence
- [ ] `/v1/chat` returns validation metadata

## Spark Prerequisites

- [ ] `nvidia-smi` succeeds
- [ ] `docker --version` succeeds
- [ ] Docker daemon running
- [ ] cgroup v2 and Spark baseline settings verified

## NemoClaw Bring-Up

- [ ] NemoClaw installed
- [ ] OpenShell installed
- [ ] `nemoclaw onboard` completed
- [ ] `nemoclaw <assistant-name> status` healthy

## Gracey Hardware Mode

- [ ] `project.mode` set to `hardware`
- [ ] Four assistants enabled
- [ ] little-indian lane (`fast`, `thinker`) started
- [ ] big-indian lane (`heavy`, `architect`) started

## Runtime Selection

- [ ] Benchmarked vLLM and TRT-LLM per role
- [ ] Runtime winner selected per role
- [ ] `platform/inference/role_registry.yaml` updated

## Final Validation

- [ ] End-to-end route and chat tests pass
- [ ] Validation checks behave as expected
- [ ] Decisions and metrics documented
- [ ] Rollback snapshot saved
