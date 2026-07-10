---
name: feedback-al-query-sqljointype
description: AL query dataitem join-type property is SqlJoinType, not DataItemJoinType
metadata:
  type: feedback
---

On a nested (child) `dataitem` inside a `query` object, the join-type property is **`SqlJoinType`** (values `InnerJoin`, `LeftOuterJoin`, `RightOuterJoin`, `FullOuterJoin`, `CrossJoin`), paired with `DataItemLink` for the join condition.

**Why:** Writing `DataItemJoinType = LeftOuterJoin;` on a query's child dataitem compiles-fails with AL0124 ("property cannot be used in this context") — that property name doesn't exist on query dataitems. Confirmed while building query 50607 "Resource List Sections" in [[project_dailyoptimizer]] (2026-07-10); `al_compile` caught it immediately and the fix was a one-line rename to `SqlJoinType`.

**How to apply:** Whenever adding a new multi-dataitem AL `query` object with a LEFT OUTER JOIN (or any non-default join) between a parent and child dataitem, use `SqlJoinType`, not `DataItemJoinType`. (Reports use a different property shape entirely — `DataItemLinkReference` + `DataItemLink`, no join-type property — don't cross-apply Report conventions to Query objects either.)
