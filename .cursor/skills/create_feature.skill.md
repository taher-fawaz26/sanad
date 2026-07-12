# Create Feature Skill

Triggered when the user says "create a new feature", "scaffold feature X", or "add feature X".

## Workflow

1. Determine mode:
   - Shared business logic → `melos feature:create <name> --shared`
   - Provider UI only → `melos feature:create <name> --app provider`
   - Client UI only → `melos feature:create <name> --app client`
   - UI + backend → add `--with-backend`

2. Run generator, then `melos bootstrap`

3. Add `<Feature>Module()` to app `moduleRegistry` list (one line)

4. For app features: register routes in app router

5. Verify keys in `en-US.json` and `ar-AR.json`

6. Run `melos validate:arch`

## Reference

- `docs/FEATURE_GUIDE.md`
- `packages/auth/` canonical implementation
