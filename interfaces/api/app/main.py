from fastapi import FastAPI

from .config_loader import load_role_registry, load_routing_policy, load_stack_config
from .contracts import ChatRequest, ChatResponse
from .router_engine import AgenticRouter

app = FastAPI(title="Gracey Router API", version="0.3.0-agentic-scaffold")

STACK_CONFIG = load_stack_config()
ROUTING_POLICY = load_routing_policy()
ROLE_REGISTRY = load_role_registry()
ROUTER = AgenticRouter(routing_policy=ROUTING_POLICY, role_registry=ROLE_REGISTRY)


@app.get("/healthz")
def healthz() -> dict:
    return {
        "status": "ok",
        "mode": STACK_CONFIG.get("project", {}).get("mode", "mock"),
        "hardware_required": False,
        "assistants_count": STACK_CONFIG.get("project", {}).get("assistants_count", 4),
        "resource_lanes": ["little-indian", "big-indian"],
    }


@app.post("/v1/route")
def route(req: ChatRequest) -> dict:
    decision = ROUTER.route(req)
    return decision.model_dump()


@app.post("/v1/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    routed = ROUTER.route_and_respond(req)
    return ChatResponse(
        role_selected=routed.route.role_selected,
        assistant_selected=routed.route.assistant_selected,
        lane_selected=routed.route.lane_selected,
        mode=STACK_CONFIG.get("project", {}).get("mode", "mock"),
        classifier_used=routed.route.classifier_used,
        confidence=routed.route.confidence,
        validation=routed.validation,
        reply=routed.response_text,
    )
