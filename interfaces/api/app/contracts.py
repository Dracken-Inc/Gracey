from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    user_id: str = "anonymous"
    role_hint: str = "auto"  # auto | fast | heavy | thinker | architect
    assistant_hint: str | None = None


class RouteDecision(BaseModel):
    role_selected: str
    assistant_selected: str
    lane_selected: str
    classifier_used: str
    confidence: float
    reasons: list[str]


class ValidationResult(BaseModel):
    passed: bool
    score: float
    checks: dict[str, bool]
    notes: list[str]


class ChatResponse(BaseModel):
    role_selected: str
    assistant_selected: str
    lane_selected: str
    mode: str
    classifier_used: str
    confidence: float
    validation: ValidationResult
    reply: str
