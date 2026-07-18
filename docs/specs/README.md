# Product specifications

This directory is the source of truth for intended Vibe Living behavior and development constraints.

## Spec-first rule

Every new feature, behavior change, bug fix, or development-environment change must begin with a specification change in this directory. Implementation starts only after the relevant spec describes:

1. the problem and scope;
2. required behavior and explicit non-goals;
3. acceptance criteria;
4. verification or Harness coverage.

If implementation and a specification disagree, update and review the specification before changing code. Pull requests must link the relevant specification and explain any spec delta.

## Specifications

- [Development workflow](development-workflow.md)
- [Local Harness](harness.md)
