# Coding Standards (Review-Time Guardrails & Judgement Calls)

> **Context Separation Rule (Matt Pocock's `/retro` & `/code-review` Principle)**:
> - This file is **NOT** auto-injected into every agent's global `instructions` so `implementer` keeps maximum context budget for code exploration, TDD, and debugging.
> - This file **IS** mandatory reading for **`@reviewer`** (during `/code-review` Standards axis) and **`architect` / `implementer`** (during `/retro` session retrospectives).
> - **Mechanical vs Judgement Rule**: Any rule that can be checked deterministically (formatting, import order, banned syntax, typechecking) belongs in the sub-repo's compiler / linter / test suite. Only put **judgement calls**, **cross-repo architectural invariants**, and **battle-scarred anti-patterns (with concrete incident examples)** in this file.
> - Sub-repos may also define a repo-specific `repos/<repo>/CODING_STANDARDS.md`; when both exist, `@reviewer` checks both (sub-repo rules override workspace defaults where explicitly noted).

---

## 1. Deep Modules & Narrow Interfaces (Ousterhout's Principle)

- **Prefer Deep Modules over Shallow Pass-Throughs**:
  - A module should expose a **narrow, simple public interface (Seam)** while hiding complex implementation details inside ("turn off the light inside the module").
  - For stateful UI/workflow logic, consolidate scattered state into a pure **reducer or state machine** (high locality, testable without DOM/network mocks).
  - _Anti-pattern_: Splitting one cohesive domain operation across 4 thin pass-through classes where every internal helper is `public` and tested with 1:1 mock-heavy unit tests.

---

## 2. Three "Lying Tests" Forbidden in Unit & Acceptance Suites

> A green test suite does NOT mean safe to merge if the tests are lying. `@reviewer` and `qa` must reject these three patterns:

1. **Tautological Tests (同义反复测试)**:
   - Asserting a constant equals itself or copying the implementation formula verbatim into the assertion (`expect(MAX_LIMIT).toBe(280)`). Tests must assert observable input-to-output behavior at the Seam.
2. **Structure-Sensitive Tests (结构敏感测试)**:
   - Reading source files as text, asserting private method call order, or asserting internal DOM/AST structure that breaks on any valid refactor while behavior is unchanged.
3. **Cannot-Fail / Reality-Divergent Mocks (不可能失败的假 Mock)**:
   - Replacing critical runtime/platform constraints (e.g., transaction boundaries, serialization, runtime lifecycle rules) with permissive fake objects that bypass the exact failure modes that happen in production.
4. **"Able to Fail" Iron Law (没见过红灯的检查不可信)**:
   - A test, assertion, or live verification check that you have never observed failing proves nothing. During TDD or verification setup, prove the check actually catches a broken state (Red) before trusting Green.
5. **Anti-Tampering Guardrail (严禁篡改护栏逃避报错)**:
   - Agents must **never** weaken compiler, typechecker, or linter configurations, nor add unjustified inline suppression directives/ignore comments to silence errors. Fix the root cause in code; if an exemption is genuinely required, it must carry an explicit reason and be surfaced for human approval.

---

## 3. Shared Contract & Domain Language Discipline (Steering Words)

- **Write Rules with Compressed "Steering Words" (引导词)**:
  - Express architectural and coding standards using dense, canonical technical terms (e.g., *"Use optimistic updates"*, *"Isolate in an error boundary"*, *"State lives in a pure reducer"*, *"Test at the HTTP seam"*) rather than verbose, ambiguous prose.
- **Speak the `GLOSSARY.md` Language (Enforce `_Avoid_` Blacklist)**:
  - Identifiers (DTO fields, API parameters, method names, error codes) must use the canonical terms in `repos/team-wiki/GLOSSARY.md` and strictly avoid the terms listed under `_Avoid_`.
- **Single Source of Precision & Validation (`shared-lib`)**:
  - Money, decimals, rounding modes, and shared error codes must go through the canonical shared library (`shared-lib` defined in `AGENTS.md`).
  - _Why (Incident Example)_: Hand-rolling decimal rounding or ad-hoc validation inside individual services causes 1-cent drift on boundary values across upstream and downstream layers.
- **No Unconstrained Dynamic/Untyped Escapes or Silent Fallbacks**:
  - Every unconstrained dynamic type escape, raw untyped map, or swallowed exception is a type-system leak that hides runtime 500s from compile-time checks.

---

## 4. Human Review Leverage: "Never Write the Same PR Comment Twice" (`/retro`)

> **The Three Brakes**: Brake 1 = Automated Checks (Types/Linter/Tests) → Brake 2 = Automated Review (`@reviewer` reading this file) → Brake 3 = Human Review.
> **Human-in-the-Loop Iron Law**: Every time a human reviewer writes a comment on a PR (or rejects an agent's output), **that comment must never be written a second time**. Immediately feed the human's taste/feedback upstream via `/retro`:
> - If it is mechanical → turn it into a deterministic linter rule or test (Brake 1);
> - If it is a judgement call → append it below with a concrete incident example so `@reviewer` catches it automatically next time (Brake 2).

> Format each `/retro` entry below as:
> `### [Rule Title using Steering Words] — Added via /retro (<date> / <JIRA-KEY>)`
> - **Rule**: Concise steering-word rule.
> - **Why (Real PR Comment / Incident)**: The concrete failure or human PR review comment this rule prevents from ever repeating.
