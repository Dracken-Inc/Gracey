from __future__ import annotations

from dataclasses import dataclass


LITTLE_INDIAN_LANE = "little-indian"
BIG_INDIAN_LANE = "big-indian"


@dataclass
class LaneSelection:
    lane: str
    reasons: list[str]


class ResourceManager:
    """Maps selected role to compute lane for resource-aware routing."""

    little_lane_roles = {"fast", "thinker"}
    big_lane_roles = {"heavy", "architect"}

    def select_lane(self, role: str, complexity_score: float, force_big_lane: bool) -> LaneSelection:
        reasons: list[str] = []

        if force_big_lane:
            reasons.append("risk_or_validation_path")
            return LaneSelection(lane=BIG_INDIAN_LANE, reasons=reasons)

        if role in self.big_lane_roles:
            reasons.append("role_requires_big_lane")
            return LaneSelection(lane=BIG_INDIAN_LANE, reasons=reasons)

        if complexity_score >= 0.78:
            reasons.append("complexity_threshold")
            return LaneSelection(lane=BIG_INDIAN_LANE, reasons=reasons)

        reasons.append("default_little_lane")
        return LaneSelection(lane=LITTLE_INDIAN_LANE, reasons=reasons)
