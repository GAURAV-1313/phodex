#!/usr/bin/env python3
"""One-time setup for WORKER_ENGINE=managed.

Creates the Managed Agents environment and agent that every Phodex task
session references, then prints the IDs to put in the backend environment:

    ANTHROPIC_API_KEY=sk-ant-... python3 scripts/setup_managed_agent.py

Agents are persistent and versioned — run this once per deployment, not per
task. To change the prompt or tools later, update the agent (which bumps its
version) instead of creating a new one.
"""

from __future__ import annotations

import argparse
import sys

SYSTEM_PROMPT = (
    "You are Phodex, an AI software engineer executing coding tasks on behalf of a "
    "developer working from their phone. The repository is mounted under /workspace. "
    "Work carefully, keep commits small and well described, run the project's checks "
    "when they exist, and finish by pushing to the current branch. Reply with concise "
    "operational logs and a final summary of what changed."
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Create the Phodex managed agent + environment")
    parser.add_argument("--name", default="phodex-cloud")
    parser.add_argument("--model", default="claude-opus-5")
    parser.add_argument(
        "--ask-for",
        default="bash",
        help="Comma-separated built-in tools that require phone approval (default: bash).",
    )
    parser.add_argument(
        "--networking",
        default="unrestricted",
        choices=["unrestricted", "limited"],
        help="Sandbox egress policy. 'limited' still allows package managers.",
    )
    args = parser.parse_args()

    try:
        import anthropic
    except ImportError:  # pragma: no cover
        print("pip install anthropic first", file=sys.stderr)
        return 1

    client = anthropic.Anthropic()

    networking = (
        {"type": "unrestricted"}
        if args.networking == "unrestricted"
        else {"type": "limited", "allow_package_managers": True, "allowed_hosts": ["github.com"]}
    )
    environment = client.beta.environments.create(
        name=f"{args.name}-env",
        config={"type": "cloud", "networking": networking},
    )

    ask_for = [name.strip() for name in args.ask_for.split(",") if name.strip()]
    agent = client.beta.agents.create(
        name=args.name,
        model=args.model,
        system=SYSTEM_PROMPT,
        tools=[
            {
                "type": "agent_toolset_20260401",
                "default_config": {
                    "enabled": True,
                    "permission_policy": {"type": "always_allow"},
                },
                "configs": [
                    {"name": name, "permission_policy": {"type": "always_ask"}} for name in ask_for
                ],
            }
        ],
    )

    print("Add these to the backend environment (Fly secrets / .env):")
    print("WORKER_ENGINE=managed")
    print(f"MANAGED_AGENT_ID={agent.id}")
    print(f"MANAGED_ENVIRONMENT_ID={environment.id}")
    print(f"# agent version: {getattr(agent, 'version', '?')}; approvals required for: {ask_for}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
