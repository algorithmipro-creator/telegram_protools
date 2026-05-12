# Track A Treasury Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Acton empty scaffold with the Track A Treasury-first contract after the WSL/Acton scaffold baseline is verified.

**Architecture:** Implement a single custom `Treasury.tolk` contract with owners, threshold, payout proposals, creator auto-approval, public owner approvals, cancellation, expiry checks, and TON payout execution. Splitter, frontend, backend, Track B, and anonymous/ZK voting remain out of scope.

**Tech Stack:** Acton, Tolk, Acton test runner, generated wrappers, WSL Ubuntu.

---

## Status

This plan is intentionally a stub until the generated Acton scaffold is present in the repository and the exact template paths/types can be inspected.

## Required Inputs Before Expansion

- `Acton.toml` exists.
- `contracts/Empty.tolk` exists.
- `contracts/types.tolk` exists.
- `tests/contract.test.tolk` exists.
- `wrappers/Empty.gen.tolk` exists.
- `acton build` passes.
- `acton test` passes.

## Expansion Rule

After the scaffold baseline passes, replace this stub with a full code-level plan that includes exact `Treasury.tolk`, `types.tolk`, tests, wrapper generation, and deployment script changes.
