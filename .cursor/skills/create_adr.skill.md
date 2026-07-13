# Create ADR Skill

Triggered when the user says "create an ADR", "document this decision", or "architecture decision record".

## Workflow

1. Read `docs/adr/0000-template.md`
2. Determine next number from `docs/adr/README.md` index
3. Create `docs/adr/NNNN-short-title.md` with all sections filled
4. Update `docs/adr/README.md` index row
5. Link related ADRs and docs

## Quality Checklist

- [ ] Context explains the forcing problem
- [ ] Decision is specific and actionable
- [ ] Alternatives table has realistic rejected options
- [ ] Consequences cover positive, negative, and risks
