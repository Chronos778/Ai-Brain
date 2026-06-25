---
name: python
description: Type-hinted Python with Pydantic, FastAPI, and ML pipeline patterns
---
# Python

Type hints everywhere. Pydantic for data. Flask for APIs, FastAPI for async.

## How I Build
- Type hints on all function signatures. f-strings for formatting. 
- `pathlib.Path` for all file operations. Never `os.path`.
- Pydantic models for structured data. Dataclasses when validation isn't needed.
- Flask + Blueprints for lightweight APIs. FastAPI when I need async + auto-docs.
- Virtual environments always. `requirements.txt` or `pyproject.toml`.
- pytest for testing. Black for formatting.

## My Python Projects
- **EcoGuard-ML**: Ecological monitoring with machine learning
- **LifeTrack**: Health records — React frontend + Flask backend
- **neural-visualizer**: ML model visualization

## Expert Decisions

**Data science**: Reproducibility first — seed everything (`np.random.seed`, `torch.manual_seed`), pin versions. Train/test split before any exploration to prevent data leakage. Feature engineering in named functions, not notebook cells.

**Pandas**: Vectorized operations over loops — `df.apply()` never `iterrows()`. Method chaining: `df.query(...).groupby(...).agg(...)`. Specify dtypes on read for memory. Consider Polars for large datasets.

**Flask**: Application factory pattern (`create_app()`). Blueprints by feature. Request validation with Pydantic. Error handlers with consistent JSON responses. Celery for background tasks.

**Error handling**: Catch specific exceptions, never bare `except:`. `raise ... from ...` to preserve traceback. Context managers (`with`) for every resource. Logging module over print, always.

## Mistakes That Cost Hours
- Mutable default arguments (`def f(x=[])`) — shared state between calls, horrifying bugs
- `import *` — namespace pollution, can't trace where anything comes from
- Bare `except: pass` — silently swallows everything including KeyboardInterrupt
- `os.path` string juggling — `pathlib.Path` is cleaner and cross-platform
- Jupyter notebooks as production code — extract to `.py` modules, test properly
- `%` or `.format()` — f-strings are the standard
