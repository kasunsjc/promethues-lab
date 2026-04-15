# Copilot Instructions

## Branching Strategy

- **Never commit directly to `main`.** All changes must go through a feature branch and pull request.
- Create a new feature branch for every change, using the naming convention:
  - `feature/<short-description>` – for new features or enhancements
  - `fix/<short-description>` – for bug fixes
  - `docs/<short-description>` – for documentation updates
  - `chore/<short-description>` – for maintenance tasks (dependency updates, CI changes)

## Pull Request Workflow

1. Create a feature branch from the latest `main`:
   ```bash
   git checkout main && git pull origin main
   git checkout -b feature/<short-description>
   ```
2. Make changes and commit with clear, descriptive messages.
3. Push the branch and open a pull request targeting `main`.
4. Ensure all CI checks pass before requesting review:
   - Quick Validation
   - Full Stack Validation
   - Alert System Test
   - Load Test Validation
5. PRs require at least one approval before merging.
6. Use **squash merge** to keep `main` history clean.
7. Delete the feature branch after the PR is merged.

## Commit Messages

Use conventional commit format:
- `feat: add new alerting rule for disk usage`
- `fix: correct MySQL exporter connection string`
- `docs: update README with Thanos setup instructions`
- `chore: bump Grafana image to latest version`

## Code Review Checklist

- Configuration files (`prometheus.yml`, `alert_rules.yml`, etc.) are valid.
- Docker Compose changes are tested locally with `docker compose config`.
- New dashboards include a description and appropriate variables.
- Alert rules include `summary` and `description` annotations.
- No secrets or credentials are committed in plain text.
