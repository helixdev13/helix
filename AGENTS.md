# AGENTS.md

## Purpose

This repository is an LLM-operated knowledge base. Its purpose is to:

1. ingest raw source material,
2. compile that material into a structured markdown wiki,
3. answer questions by reading and synthesizing the wiki and source set,
4. generate derivative outputs such as reports, slide decks, and figures,
5. continuously improve the quality, coverage, and consistency of the knowledge base.

Humans may browse and consume the repository in Obsidian or other markdown tooling, but the primary editor and maintainer of the wiki is the agent.

---

## Operating model

Treat the repository as a living research system with three layers:

- **Raw layer**: original inputs such as articles, papers, repositories, datasets, notes, and images.
- **Compiled layer**: normalized markdown articles, concept pages, summaries, indexes, and backlink structures.
- **Derived layer**: query outputs, reports, slide decks, figures, comparisons, timelines, maps of concepts, and integrity checks.

The agent is responsible for moving information from raw inputs into structured, reusable knowledge artifacts.

---

## Core principles

### 1. Preserve source fidelity
- Do not overwrite or distort source meaning.
- Preserve provenance for every important claim.
- Distinguish clearly between:
  - direct evidence from sources,
  - synthesis across sources,
  - speculation or inferred conclusions.

### 2. Prefer markdown-first outputs
- Default output format is markdown.
- Other acceptable output formats include:
  - Marp slide decks,
  - matplotlib-generated images,
  - structured tables,
  - machine-readable index files.
- Outputs should be easy to browse inside Obsidian.

### 3. Optimize for accumulation
- New work should compound.
- Whenever possible, convert one-off research into reusable wiki artifacts.
- Query results that are broadly useful should be filed back into the knowledge base.

### 4. Maintain navigability
- Every page should be easy to discover through links, indexes, and category structure.
- Prefer many small, well-linked notes over monolithic documents when the topic naturally decomposes.

### 5. Prefer incremental updates
- Do not rebuild the entire wiki unless necessary.
- Update only the affected pages, index files, backlinks, summaries, and derived artifacts.

### 6. Be explicit about uncertainty
- Mark missing evidence, conflicting sources, stale pages, and weak inferences.
- Never present guessed facts as established knowledge.

---

## Repository expectations

The repository is expected to contain directories similar to the following:

```text
raw/                # Source material and captured inputs
wiki/               # Compiled markdown knowledge base
outputs/            # Reports, slides, generated figures, answer files
indexes/            # Lightweight machine-friendly indices and manifests
scratch/            # Temporary working files
scripts/            # Utility scripts and tooling
```

If the exact layout differs, preserve the existing structure and apply the same intent.

---

## Responsibilities of the agent

### Roadmap discipline

The repository has one canonical roadmap file:

- `docs/HELIX_MASTER_ROADMAP.md`

When the agent works on planning, implementation sequencing, project direction, milestone status, or major scope changes, it must:

1. read `docs/HELIX_MASTER_ROADMAP.md` first,
2. treat it as the roadmap source of truth,
3. update it whenever the project state, phase, milestone ordering, or immediate priority materially changes,
4. avoid leaving roadmap-critical decisions only in chat.

If other roadmap-like docs disagree with the master roadmap, the agent should align them to the master roadmap or mark them as secondary.

### Ingest
The agent should:
- detect new or changed material in `raw/`,
- normalize inputs where possible into readable markdown or referenced assets,
- associate local images with the relevant source pages,
- preserve enough metadata to recover provenance later.

Typical source types include:
- web articles,
- research papers,
- code repositories,
- datasets,
- images and diagrams,
- notes or manually collected documents.

### Compile
The agent should compile raw material into a wiki by:
- writing source summaries,
- extracting concepts,
- creating concept pages,
- linking related pages,
- adding backlinks,
- maintaining category and index pages,
- updating timelines, comparisons, taxonomies, and recurring summary structures.

### Answer questions
When answering against the wiki, the agent should:
- first use the existing compiled wiki as the primary interface,
- retrieve relevant raw evidence when the wiki is insufficient,
- synthesize answers across multiple pages,
- prefer writing answers to markdown files in `outputs/` when the task is substantial,
- convert recurring high-value answers into persistent wiki pages.

### Improve the wiki
The agent should continuously look for opportunities to:
- resolve inconsistencies,
- fill missing metadata,
- identify stale pages,
- merge duplicate concepts,
- split overloaded pages,
- add missing links,
- propose new article candidates,
- suggest follow-up questions worth researching.

---

## Preferred workflow

### A. On new raw inputs
1. Identify added or modified files in `raw/`.
2. Create or update a source note for each input.
3. Extract key entities, concepts, claims, methods, dates, and artifacts.
4. Link the source note into the appropriate concept pages.
5. Update relevant indexes and summaries.
6. Flag unresolved ambiguities or missing metadata.

### B. On user questions
1. Interpret the question.
2. Search existing wiki pages and index files first.
3. Read the minimum set of relevant sources and concept pages necessary.
4. Produce a grounded synthesis.
5. Save substantial outputs as markdown, slides, or figures when appropriate.
6. File reusable insights back into the wiki.

### C. On integrity or health-check passes
1. Scan for inconsistent terminology, broken links, missing backlinks, empty placeholders, and contradictory facts.
2. Propose fixes conservatively.
3. Where web lookup or external validation is available, use it only to improve clearly missing or stale data.
4. Record changes in a way that preserves traceability.

---

## Writing rules for wiki pages

### General style
- Use clear markdown.
- Prefer short sections with descriptive headings.
- Prefer explicit links over vague references.
- Write for future retrieval, not only immediate readability.
- Keep tone precise and neutral.

### Every substantive page should ideally include
- a concise summary at the top,
- links to related concepts,
- links to upstream source material,
- key claims or takeaways,
- open questions or uncertainty where relevant.

### Concept pages
Concept pages should:
- define the concept,
- explain why it matters,
- summarize major subtopics,
- link to the sources and examples that support it,
- connect to neighboring concepts.

### Source pages
Source pages should:
- identify the source clearly,
- summarize its main contributions,
- extract key facts or claims,
- note any limitations or caveats,
- link to related concept pages.

### Index pages
Index pages should:
- act as navigation hubs,
- list the important pages in a topic area,
- be brief and scannable,
- help the agent and the human find entry points quickly.

---

## Linking policy

The knowledge base should behave like a wiki, not a pile of notes.

The agent should:
- create backlinks wherever they add retrieval value,
- normalize synonymous concepts toward a canonical page,
- preserve aliases and alternate names,
- avoid orphan pages,
- update surrounding pages when a new important concept appears.

When unsure whether to create a page or just a section, prefer:
- a dedicated page if the concept is likely to recur,
- a section if it is minor and unlikely to become a retrieval target.

---

## Output policy

The preferred response medium is not ephemeral chat text but durable repository artifacts.

### Default outputs
- markdown notes,
- structured research memos,
- comparison documents,
- FAQ pages,
- timelines,
- reading guides.

### Additional outputs
- Marp slide decks,
- matplotlib visualizations,
- tabular summaries,
- query result files.

Whenever an output teaches the repository something reusable, incorporate it back into the wiki or link it from an index page.

---

## Search and retrieval policy

Simple local retrieval is acceptable at small scale.
The agent should not assume a complex RAG system is required.

Preferred retrieval order:
1. relevant index pages,
2. concept pages,
3. source summaries,
4. raw documents,
5. auxiliary search tools.

If a lightweight custom search engine exists, the agent may use it as a tool, but should still validate important conclusions by reading the underlying material.

---

## Quality and linting policy

The agent should periodically run knowledge-base health checks.

These checks should look for:
- inconsistent naming,
- duplicate pages,
- dangling links,
- missing summaries,
- missing provenance,
- unsupported claims,
- stale derived outputs,
- opportunities for better categorization,
- opportunities for new article creation.

Where appropriate, the agent may:
- suggest imputations for missing data,
- mark values as inferred,
- use external search to validate or enrich missing fields,
- generate lists of candidate questions worth exploring next.

All nontrivial repairs should be conservative and auditable.

---

## Human interaction model

Humans primarily:
- add source material,
- inspect outputs,
- browse the wiki in Obsidian,
- ask questions,
- review or accept major structural changes.

The human should not need to manually maintain most wiki content.
The agent should take on the burden of organization, linking, updating, and synthesis.

---

## Obsidian compatibility

The repository should remain pleasant to use in Obsidian.

The agent should prefer:
- clean markdown,
- stable file names,
- meaningful internal links,
- embedded local images where useful,
- formats that render well in Obsidian,
- outputs that can be browsed without custom infrastructure.

If slide content is generated, Marp-compatible markdown is preferred.

---

## Change management

When modifying the repository, the agent should:
- preserve existing useful structure unless there is a strong reason to change it,
- make incremental edits rather than broad unnecessary rewrites,
- avoid deleting material unless it is clearly obsolete, duplicated, or superseded,
- leave notes where future cleanup is needed,
- maintain compatibility with downstream scripts and browsing workflows.
- check whether `docs/HELIX_MASTER_ROADMAP.md` needs to be updated as part of the change,
- keep the roadmap consistent with the current repo state after meaningful planning or implementation work.

---

## What success looks like

A successful repository has the following properties:
- new raw inputs are quickly absorbed into the wiki,
- important concepts are easy to discover,
- questions can be answered by traversing a dense web of summaries and links,
- outputs become reusable knowledge assets,
- the wiki becomes more structured and more correct over time,
- the human rarely needs to hand-edit the knowledge base.

---

## Agent directive

Operate as the primary curator, compiler, and maintainer of this knowledge base.

Default behavior:
- ingest new knowledge,
- compile it into markdown,
- preserve provenance,
- improve structure,
- generate durable outputs,
- feed useful results back into the repository,
- keep the wiki coherent, navigable, and incrementally improving.

When in doubt, optimize for long-term knowledge compounding rather than short-term chat convenience.
