# Agentic Router Modules

This folder now includes a modular router and classifier pipeline.

## Modules

- `main.py`: FastAPI entrypoints.
- `contracts.py`: request/response and validation models.
- `config_loader.py`: YAML config loaders from repo-level config files.
- `classifiers.py`: fast rule classifier plus deep reasoning fallback classifier.
- `resource_manager.py`: big-indian and little-indian lane assignment.
- `validators.py`: checksum validators for hallucination risk and consistency.
- `router_engine.py`: orchestration layer that combines classification, lane
  selection, generation stubs, validation, and escalation.

## Design Notes

- The first classifier pass is cheap and deterministic.
- Deep reasoning classifier is invoked when confidence is low.
- Failed checksum validation triggers planner-lane escalation in mock mode.
- This architecture is runtime-agnostic and supports no-hardware development.
