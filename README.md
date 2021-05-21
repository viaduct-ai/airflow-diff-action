# dag-diff
A GitHub action to show diffs of Airflow DAGs.

Outputs a textual diff of the DAG dependencies, and also generates PNG images of the rendered DAG structure.

Example usage that creates a pull request comment with the diff, and uploads the PNG images as artifacts.

```yaml
name: Diff Airflow DAG

on: [pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - uses: viaduct-ai/airflow-diff-action@main
        id: diff
      - uses: actions/github-script@v4
        if: ${{ steps.diff.outputs.diff }}
        env:
          DIFF: ${{ steps.diff.outputs.diff }}
        with:
          github-token: ${{secrets.GITHUB_TOKEN}}
          script: |
            const { DIFF } = process.env
            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '**Airflow DAG diff**\n\nView images of modified DAGs in the GitHub Action.\n\n'+DIFF,
            })
      - uses: actions/upload-artifact@v2
        with:
          name: airflow-diff-results
          path: ${{ github.workspace }}/airflow-diff-results
```
