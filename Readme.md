# LGTMLottery

## Overview
LGTM Lottery is a GitHub Action designed to post a random LGTM (Looks Good To Me) image in comments on PRs (Pull Requests) or Issues in your repository. This action can be used to add a bit of fun and positivity to your project's PRs and Issues.

## Usage

```yaml
name: LGTM Action

on:
  issue_comment:
    types: [created]

jobs:
  lgtm-job:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Run Custom LGTM Action
        uses: aknow2/LGTMLottery@v0.1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pattern: '^(lgtm|LGTM)$' # this is optional. 

```
The `github-token` field should be set to your GitHub token, which is used to authenticate the action. The pattern field is optional and can be used to specify a regular expression pattern that triggers the posting of an image. If not provided, it defaults to `^(lgtm|LGTM)$`.

This will trigger the LGTMLottery action whenever a new PR or Issue is created in your repository and a comment matches the specified pattern.
