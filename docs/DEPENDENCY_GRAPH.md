# Dependency Graph

## Overview

```mermaid
flowchart TB
  subgraph apps [Apps]
    Client[sanad_client]
    Provider[sanad_provider]
  end

  subgraph features [Feature Packages]
    Auth[auth]
    OTP[otp]
    FP[forgot_password]
    CP[change_password]
  end

  subgraph ui [UI Packages]
    DS[design_system]
    SW[shared_widgets]
    Loc[localization]
    SB[shared_blocs]
  end

  subgraph infra [Infrastructure]
    Network[network]
    Storage[storage]
    API[api]
    Config[config]
    Flavors[flavors]
  end

  subgraph core_pkgs [Core]
    Core[core]
    Domain[domain]
    Models[shared_models]
    Utils[utilities]
    Testing[testing]
    Deps[dependencies]
  end

  Client --> Auth
  Client --> DS
  Client --> Loc
  Provider --> Auth
  Provider --> DS
  Provider --> Loc
  Provider --> SW

  Auth --> OTP
  Auth --> Network
  Auth --> Storage
  Auth --> DS
  Auth --> Loc
  OTP --> Auth
  OTP --> SW
  FP --> Auth
  FP --> OTP

  DS --> Core
  SW --> DS
  Loc --> Core
  SB --> Auth
  SB --> DS

  Network --> Core
  Storage --> Core
  Storage --> Network
  API --> Core
  API --> Network
  Config --> Core
  Flavors --> Config

  Domain --> Core
  Models --> Core
  Utils --> Core
  Testing --> Core
  Testing --> Domain
```

## Dependency Direction Rules

```
apps → feature packages → UI/infra packages → core
```

Allowed:
- `sanad_provider` → `auth` → `network` → `core`
- `auth` → `design_system` → `core`

Forbidden:
- `core` → `auth` (reverse)
- `auth` → `sanad_provider` (package importing app)
- `domain` → `data` (layer violation)

## Layer Dependencies (Feature Packages)

```
presentation/ → domain/, design_system/, localization/
data/ → domain/, network/, storage/
domain/ → core/ only
di/ → all layers
routes/ → (path constants only)
```

## Known Issues

- `settings` package exists on disk but is not in workspace — do not depend on it
- `api`, `analytics`, `notifications`, `change_password` are stubs with minimal implementation
