# Create Feature Skill

Triggered when the user says "create a new feature", "scaffold feature X", or "add feature X".

## Workflow

1. Determine mode and run generator (always use `melos run` + `--` separator):
   - Shared business logic → `melos run feature:create -- <name> shared`
   - Provider UI only → `melos run feature:create -- <name> provider`
   - Client UI only → `melos run feature:create -- <name> client`
   - UI + backend package → `melos run feature:create -- <name> provider with-backend`

2. Run `melos bootstrap`

3. Add `<Feature>Module()` to app `moduleRegistry` list (one line)

4. For app features: register routes in app router

5. Verify keys in `en-US.json` and `ar-AR.json`

6. Run `melos validate:arch`

## Reference

- `docs/FEATURE_GUIDE.md`
- `packages/features/auth/` canonical implementation
