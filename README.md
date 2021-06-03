# dag-diff
A GitHub action to show diffs of Airflow DAGs.

Outputs a textual diff of the DAG dependencies, and also generates PNG images of the rendered DAG structure.

Example usage that:

* creates a pull request comment with the diff
* deletes previous pull request comments
* uploads the diffs and PNG images as artifacts

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
        env:
          DIFF: ${{ steps.diff.outputs.diff }}
        with:
          github-token: ${{secrets.GITHUB_TOKEN}}
          script: |
            const { data: comments } = await github.issues.listComments({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
            })
            for (let c of comments) {
              if (c.user.login == 'github-actions[bot]' && c.body.startsWith('**Airflow DAG diff**')) {
                github.issues.deleteComment({
                  comment_id: c.id,
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                })
              }
            }
            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '**Airflow DAG diff**\n\n'+process.env.DIFF,
            })
      - uses: actions/upload-artifact@v2
        with:
          name: airflow-diff-results
          path: ${{ github.workspace }}/airflow-diff-results
```
