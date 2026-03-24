from __future__ import annotations

from .contracts import ValidationResult


class HallucinationValidator:
    """Lightweight placeholder hallucination risk checks for mock mode."""

    risk_markers = ["always", "guaranteed", "100%", "never fails"]

    def evaluate(self, request_text: str, response_text: str) -> ValidationResult:
        checks: dict[str, bool] = {}
        notes: list[str] = []

        checks["non_empty"] = bool(response_text.strip())

        lowered = response_text.lower()
        checks["overclaim_risk"] = not any(marker in lowered for marker in self.risk_markers)
        if not checks["overclaim_risk"]:
            notes.append("contains_strong_certainty_marker")

        # For scaffold mode, we require role mention to ensure traceable routing.
        checks["routing_trace_present"] = "role=" in lowered

        passed = all(checks.values())
        score = sum(1 for value in checks.values() if value) / max(len(checks), 1)
        return ValidationResult(passed=passed, score=round(score, 3), checks=checks, notes=notes)


class ConsistencyValidator:
    """Checks whether reply references main user intent tokens."""

    def evaluate(self, request_text: str, response_text: str) -> ValidationResult:
        checks: dict[str, bool] = {}
        notes: list[str] = []

        req_tokens = [t for t in request_text.lower().split() if len(t) > 4][:6]
        overlap = [t for t in req_tokens if t in response_text.lower()]

        checks["minimum_overlap"] = len(overlap) >= 1 or len(req_tokens) <= 2
        if not checks["minimum_overlap"]:
            notes.append("low_intent_overlap")

        checks["contains_stub_marker"] = "scaffold" in response_text.lower()

        passed = all(checks.values())
        score = sum(1 for value in checks.values() if value) / max(len(checks), 1)
        return ValidationResult(passed=passed, score=round(score, 3), checks=checks, notes=notes)
