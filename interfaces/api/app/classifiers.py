from __future__ import annotations

from dataclasses import dataclass

from .contracts import ChatRequest


@dataclass
class Classification:
    role: str
    confidence: float
    complexity_score: float
    classifier_name: str
    reasons: list[str]


class RuleBasedClassifier:
    """Fast deterministic classifier for most routing decisions."""

    def __init__(self, policy: dict):
        self.policy = policy

    def classify(self, req: ChatRequest) -> Classification:
        text = req.message.lower()
        reasons: list[str] = []

        explicit_hint = (req.assistant_hint or req.role_hint or "").strip().lower()
        if explicit_hint and explicit_hint != "auto":
            return Classification(
                role=explicit_hint,
                confidence=0.99,
                complexity_score=0.35,
                classifier_name="rule-explicit-hint",
                reasons=["explicit_hint"],
            )

        for rule in self.policy.get("classifier", {}).get("rules", []):
            keywords = [k.lower() for k in rule.get("contains_any", [])]
            if keywords and any(k in text for k in keywords):
                reasons.append(f"keyword:{rule.get('name', 'unnamed')}")
                return Classification(
                    role=rule.get("route_to", "fast"),
                    confidence=0.82,
                    complexity_score=0.70,
                    classifier_name="rule-keyword",
                    reasons=reasons,
                )

            min_chars = rule.get("min_prompt_chars")
            if isinstance(min_chars, int) and len(req.message) >= min_chars:
                reasons.append(f"length:{rule.get('name', 'unnamed')}")
                return Classification(
                    role=rule.get("route_to", "heavy"),
                    confidence=0.84,
                    complexity_score=0.92,
                    classifier_name="rule-length",
                    reasons=reasons,
                )

        return Classification(
            role=self.policy.get("classifier", {}).get("default_role", "fast"),
            confidence=0.74,
            complexity_score=_heuristic_complexity(req.message),
            classifier_name="rule-default",
            reasons=["default_role"],
        )


class DeepReasoningClassifier:
    """Second-pass classifier used when first pass confidence is low."""

    def classify(self, req: ChatRequest, first_pass: Classification) -> Classification:
        text = req.message.lower()
        reasons = list(first_pass.reasons)

        architecture_signals = ["plan", "planner", "roadmap", "system", "migration"]
        reasoning_signals = ["prove", "why", "derive", "analyze", "root cause"]

        if any(s in text for s in architecture_signals):
            reasons.append("deep-pass:architecture")
            return Classification(
                role="architect",
                confidence=0.86,
                complexity_score=max(first_pass.complexity_score, 0.88),
                classifier_name="deep-reasoning",
                reasons=reasons,
            )

        if any(s in text for s in reasoning_signals):
            reasons.append("deep-pass:reasoning")
            return Classification(
                role="thinker",
                confidence=0.83,
                complexity_score=max(first_pass.complexity_score, 0.81),
                classifier_name="deep-reasoning",
                reasons=reasons,
            )

        reasons.append("deep-pass:no-change")
        return Classification(
            role=first_pass.role,
            confidence=max(first_pass.confidence, 0.76),
            complexity_score=max(first_pass.complexity_score, _heuristic_complexity(req.message)),
            classifier_name="deep-reasoning",
            reasons=reasons,
        )


def _heuristic_complexity(text: str) -> float:
    length_score = min(len(text) / 4000.0, 1.0)
    punctuation_score = min((text.count(",") + text.count(";")) / 20.0, 1.0)
    return round((0.65 * length_score + 0.35 * punctuation_score), 3)
