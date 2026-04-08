#!/usr/bin/env python3
"""
Mobile SDLC Orchestrator
========================
Runs a full Android/iOS feature lifecycle using the Claude Agent SDK.

Each SDLC stage spawns a specialist sub-agent with an isolated context window.
Stages 5 (security) and 6 (accessibility) run in PARALLEL.

Usage:
    python sdlc_runner.py "Build a user profile editing screen for Android"
    python sdlc_runner.py --platform ios --skip-release "Add push notification support"
    python sdlc_runner.py --stages plan,build,test "Implement offline cart sync"

Stages:
    plan          → mobile-architect    (architecture decision)
    build         → android / ios       (implementation skeleton)
    test          → mobile-test-planner (test code generation)
    review        → android-reviewer / ios-reviewer
    security      → mobile-security     ─┐ parallel
    accessibility → ui-accessibility    ─┘
    release       → release-manager     (version + release notes)
"""

import argparse
import asyncio
import sys
import textwrap
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Literal

import anyio
from claude_agent_sdk import AgentDefinition, ClaudeAgentOptions, ResultMessage, query

from agents import AGENTS

# ── Types ─────────────────────────────────────────────────────────────────────

Platform = Literal["android", "ios", "both"]
StageName = Literal["plan", "build", "test", "review", "security", "accessibility", "release"]

ALL_STAGES: list[StageName] = [
    "plan", "build", "test", "review", "security", "accessibility", "release"
]

STAGE_LABELS = {
    "plan":          "1 — PLAN          (mobile-architect)",
    "build":         "2 — BUILD         (feature skeleton)",
    "test":          "3 — TEST          (test generation)",
    "review":        "4 — CODE REVIEW   (quality gate)",
    "security":      "5 — SECURITY      (OWASP audit)     ┐ parallel",
    "accessibility": "6 — ACCESSIBILITY (WCAG 2.1 AA)     ┘ parallel",
    "release":       "7 — RELEASE       (version + notes)",
}


@dataclass
class StageResult:
    stage: StageName
    output: str
    passed: bool = True
    blockers: list[str] = field(default_factory=list)


@dataclass
class SDLCReport:
    feature: str
    platform: Platform
    results: list[StageResult] = field(default_factory=list)
    started_at: datetime = field(default_factory=datetime.now)

    def summary(self) -> str:
        lines = [
            "",
            "=" * 70,
            f"  SDLC Report — {self.feature}",
            f"  Platform: {self.platform}   Completed: {datetime.now():%Y-%m-%d %H:%M}",
            "=" * 70,
        ]
        for r in self.results:
            icon = "✓" if r.passed else "✗"
            lines.append(f"  [{icon}] {STAGE_LABELS.get(r.stage, r.stage)}")
            for b in r.blockers:
                lines.append(f"       BLOCKER: {b}")
        lines.append("=" * 70)
        return "\n".join(lines)


# ── Orchestrator ──────────────────────────────────────────────────────────────

class MobileSDLCOrchestrator:
    """
    Runs the mobile SDLC by spawning specialist Claude sub-agents.

    Architecture:
        This process is the parent orchestrator. It calls the Claude Agent SDK
        for each stage, passing the appropriate AgentDefinition. Each sub-agent
        gets its own context window scoped to its role.

        Stages 5 (security) and 6 (accessibility) run concurrently via asyncio
        since they are independent audits of the same codebase.
    """

    def __init__(
        self,
        feature: str,
        platform: Platform,
        cwd: str,
        stages: list[StageName],
        interactive: bool,
        model_override: str | None,
    ):
        self.feature = feature
        self.platform = platform
        self.cwd = cwd
        self.stages = stages
        self.interactive = interactive
        self.model_override = model_override
        self.report = SDLCReport(feature=feature, platform=platform)
        # Accumulated context passed forward between stages
        self._context: dict[StageName, str] = {}

    # ── Public entry point ────────────────────────────────────────────────────

    async def run(self) -> SDLCReport:
        print(f"\n{'='*70}")
        print(f"  Mobile SDLC Orchestrator")
        print(f"  Feature : {self.feature}")
        print(f"  Platform: {self.platform}")
        print(f"  Stages  : {', '.join(self.stages)}")
        print(f"{'='*70}\n")

        for i, stage in enumerate(self.stages):
            # Stages 5+6 run in parallel when both are active
            if stage == "security" and "accessibility" in self.stages:
                remaining = self.stages[i:]
                if "accessibility" in remaining:
                    await self._run_parallel_audit()
                    # Skip accessibility when we reach it in the loop
                    continue

            if stage == "accessibility" and "security" in self.stages:
                # Already ran in parallel above
                continue

            result = await self._run_stage(stage)
            self.report.results.append(result)

            if not result.passed and self.interactive:
                cont = input(
                    f"\n  Stage '{stage}' has blockers. Continue anyway? [y/N] "
                ).strip().lower()
                if cont != "y":
                    print("  Stopped by user.")
                    break

            if self.interactive and i < len(self.stages) - 1:
                next_stage = self.stages[i + 1] if i + 1 < len(self.stages) else None
                if next_stage and next_stage not in ("security", "accessibility"):
                    input(f"\n  ↵  Press Enter to continue to stage: {next_stage} ")

        print(self.report.summary())
        return self.report

    # ── Stage runner ──────────────────────────────────────────────────────────

    async def _run_stage(self, stage: StageName) -> StageResult:
        print(f"\n{'─'*70}")
        print(f"  Running: {STAGE_LABELS.get(stage, stage)}")
        print(f"{'─'*70}")

        prompt = self._build_prompt(stage)
        agent_key = self._agent_key(stage)
        agent_def = AGENTS[agent_key]

        options = ClaudeAgentOptions(
            cwd=self.cwd,
            allowed_tools=list(agent_def.tools or ["Read", "Grep", "Glob"]),
            agents={agent_key: agent_def},
            system_prompt=agent_def.prompt,
            max_turns=30,
            # Use a smaller model for review stages; Opus for arch/security
            model=self.model_override or self._model_for_stage(stage),
        )

        output_parts: list[str] = []

        async for message in query(prompt=prompt, options=options):
            if isinstance(message, ResultMessage):
                output_parts.append(message.result)

        output = "\n".join(output_parts)
        self._context[stage] = output

        # Simple heuristic: look for "Critical" or "BLOCKER" in output
        blockers = self._extract_blockers(output)
        passed = len(blockers) == 0

        self._print_output(stage, output)
        return StageResult(stage=stage, output=output, passed=passed, blockers=blockers)

    async def _run_parallel_audit(self) -> None:
        """Run security and accessibility audits concurrently."""
        print(f"\n{'─'*70}")
        print("  Running: SECURITY + ACCESSIBILITY (parallel)")
        print(f"{'─'*70}")

        sec_task = asyncio.create_task(self._run_stage("security"))
        a11y_task = asyncio.create_task(self._run_stage("accessibility"))

        sec_result, a11y_result = await asyncio.gather(sec_task, a11y_task)

        self.report.results.append(sec_result)
        self.report.results.append(a11y_result)

    # ── Prompt builders ───────────────────────────────────────────────────────

    def _build_prompt(self, stage: StageName) -> str:
        ctx = self._context

        base = f"Feature: {self.feature}\nPlatform: {self.platform}\n\n"

        if stage == "plan":
            return base + textwrap.dedent(f"""
                Design the architecture for this mobile feature.
                Platform: {self.platform}
                Produce: pattern choice, module structure, layer breakdown, DI wiring.
            """)

        if stage == "build":
            arch = ctx.get("plan", "No architecture context available.")
            return base + textwrap.dedent(f"""
                Architecture decision from planning stage:
                {arch}

                Now produce the implementation skeleton:
                - Domain models, repository interfaces, use cases
                - Data layer: DTOs, API service, repository impl
                - ViewModel + UiState
                - UI (Compose / SwiftUI)
                - DI module

                Write real code, not pseudocode. File by file.
            """)

        if stage == "test":
            build = ctx.get("build", "No build context available.")
            return base + textwrap.dedent(f"""
                Implementation from build stage:
                {build[:3000]}...

                Generate a full test suite:
                - ViewModel unit tests (loading→success, loading→error, retry)
                - UseCase unit tests (business rules)
                - Repository integration tests (success + error paths)
                - UI tests for main happy path

                Write actual test code with correct imports and setup.
            """)

        if stage == "review":
            build = ctx.get("build", "No build context available.")
            platform_label = "Android/Kotlin" if self.platform == "android" else "Swift/iOS"
            return base + textwrap.dedent(f"""
                Review the following {platform_label} implementation:
                {build[:4000]}...

                Apply all standards from the coding rules.
                Output: Critical / Major / Minor findings with file:line and fix.
            """)

        if stage == "security":
            build = ctx.get("build", "No build context available.")
            return base + textwrap.dedent(f"""
                Security audit the following {self.platform} code:
                {build[:4000]}...

                Check OWASP Mobile Top 10. For each finding:
                - Cite OWASP category
                - Give file:line
                - Provide a working code fix
                - Rate: Critical / High / Medium / Low
            """)

        if stage == "accessibility":
            build = ctx.get("build", "No build context available.")
            return base + textwrap.dedent(f"""
                Accessibility audit the following {self.platform} UI code:
                {build[:4000]}...

                Check WCAG 2.1 AA for mobile. For each issue:
                - WCAG criterion reference
                - FILE:LINE
                - Code fix with correct accessibility attribute
            """)

        if stage == "release":
            version = input("\n  Enter release version (e.g. 2.5.0): ").strip()
            review_output = ctx.get("review", "")
            return base + textwrap.dedent(f"""
                Prepare release {version} for {self.platform}.

                Code review summary:
                {review_output[:1000]}

                Tasks:
                1. Validate version bump in build files
                2. Run release checklist
                3. Generate user-facing release notes
                4. Output build + upload commands
            """)

        return base + f"Run the {stage} stage for this feature."

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _agent_key(self, stage: StageName) -> str:
        mapping = {
            "plan":          "architect",
            "build":         "android" if self.platform in ("android", "both") else "ios",
            "test":          "test",
            "review":        "android" if self.platform in ("android", "both") else "ios",
            "security":      "security",
            "accessibility": "accessibility",
            "release":       "release",
        }
        return mapping[stage]

    def _model_for_stage(self, stage: StageName) -> str:
        # Architecture and security warrant the best model
        if stage in ("plan", "security"):
            return "claude-opus-4-6"
        # Review, test, release can use Sonnet
        return "claude-sonnet-4-6"

    def _extract_blockers(self, output: str) -> list[str]:
        blockers: list[str] = []
        for line in output.splitlines():
            lower = line.lower()
            if "critical" in lower or "blocker" in lower:
                trimmed = line.strip().lstrip("•-*# ")
                if trimmed and len(trimmed) > 5:
                    blockers.append(trimmed[:120])
        return blockers[:5]  # Cap at 5 to avoid noise

    def _print_output(self, stage: StageName, output: str) -> None:
        # Print first 2000 chars; full output is in the report
        preview = output[:2000]
        if len(output) > 2000:
            preview += f"\n\n  ... [{len(output) - 2000} more chars] ..."
        print(f"\n{preview}\n")


# ── CLI ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Mobile SDLC Orchestrator — run Android/iOS feature lifecycle with Claude",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""
        Examples:
          python sdlc_runner.py "Build a user profile screen for Android"
          python sdlc_runner.py --platform ios "Add push notification support"
          python sdlc_runner.py --stages plan,build,test "Implement offline cart sync"
          python sdlc_runner.py --skip review,release "Security audit the payment flow"
          python sdlc_runner.py --no-interactive --output report.md "Refactor login screen"
        """),
    )
    parser.add_argument("feature", help="Feature description")
    parser.add_argument(
        "--platform", choices=["android", "ios", "both"], default="android",
        help="Target platform (default: android)"
    )
    parser.add_argument(
        "--stages", default=",".join(ALL_STAGES),
        help="Comma-separated stages to run (default: all)"
    )
    parser.add_argument(
        "--skip", default="",
        help="Comma-separated stages to skip"
    )
    parser.add_argument(
        "--cwd", default=".",
        help="Working directory for file access (default: current dir)"
    )
    parser.add_argument(
        "--no-interactive", action="store_true",
        help="Run without human gates (CI mode)"
    )
    parser.add_argument(
        "--output", default=None,
        help="Save full report to this file path"
    )
    parser.add_argument(
        "--model", default=None,
        help="Override model for all stages (e.g. claude-haiku-4-5 for cheap runs)"
    )
    return parser.parse_args()


async def main() -> None:
    args = parse_args()

    requested = [s.strip() for s in args.stages.split(",") if s.strip()]
    skipped = {s.strip() for s in args.skip.split(",") if s.strip()} if args.skip else set()
    stages = [s for s in requested if s in ALL_STAGES and s not in skipped]

    if not stages:
        print("Error: no valid stages selected.")
        sys.exit(1)

    orchestrator = MobileSDLCOrchestrator(
        feature=args.feature,
        platform=args.platform,
        cwd=str(Path(args.cwd).resolve()),
        stages=stages,
        interactive=not args.no_interactive,
        model_override=args.model,
    )

    report = await orchestrator.run()

    if args.output:
        out_path = Path(args.output)
        lines = [report.summary(), "\n\n# Stage Outputs\n"]
        for r in report.results:
            lines.append(f"\n## {r.stage.upper()}\n")
            lines.append(r.output)
        out_path.write_text("\n".join(lines))
        print(f"\n  Full report saved → {out_path}")


if __name__ == "__main__":
    anyio.run(main)
