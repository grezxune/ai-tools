---
name: aws-kit
description: AWS through the aws-kit CLI. Use to create an AWS account, add or remove any AWS resource for a project (buckets, CloudFront, queues, databases, anything), or see what runs in AWS and what it costs.
---

# aws-kit

`aws-kit` is a CLI on this machine that creates AWS accounts and deploys one CloudFormation stack per project stage. Each command prints one JSON document: read `ok`, and on failure follow `error.hint`. `aws-kit help` lists every command and flag.

## Rules
- Every change goes through a **plan** the person has seen. Run the command without `--yes`, show the person what it reports, and add `--yes` only after they say yes. This covers `bootstrap`, `account create`, `account ready`, `deploy`, and `destroy`.
- Keep every resource in the project's stack, where the kit can list, destroy, and move it. Use `aws-kit exec` for reads and experiments, and tag anything it creates with `project=<name>` and `stage=scratch`.
- Pipe secret values from AWS straight to their destination, so they stay out of the transcript.

## Add AWS to a project
1. With no `infra/` folder yet: `aws-kit project init --dir infra --project <name> --yes`, then `bun install` inside it. `infra/aws-kit.json` names the account each stage deploys to.
2. With no account yet: `aws-kit account create --name <name>`, show it, then rerun with `--yes`. Then `aws-kit account ready --account <name>` the same way. Add `--vercel-team <slug>` when a Vercel app will call AWS.
3. Write the resources in `infra/app.ts` as ordinary CDK on `stack`. Before using a service for the first time in a project, read its current AWS docs. Recipes in `aws-kit/cdk`: `PrivateBucket` for app files, `CdnBucket` for a private bucket served through CloudFront, `VercelOidcRole` for a Vercel app that reaches AWS with no key.
4. `aws-kit synth --dir infra --stage <stage>` until `passed` is true. Each violation says how to fix it.
5. `aws-kit plan --dir infra --stage <stage>`. Show the person the changes, the warnings, and the move label of each added resource. Wait for a yes.
6. `aws-kit deploy --dir infra --stage <stage> --plan <id> --yes`. Its `env` field names each stack output as an env var. Set them where the app runs, such as the Vercel project.
7. Check the feature end to end from the app.

## Other tasks
- What runs where: `aws-kit list`, with `--cost` for month-to-date spend.
- A stage's outputs: `aws-kit status --dir infra --stage <stage>`.
- Remove a stage: `aws-kit destroy --dir infra --stage <stage>`, show the report, then `--yes`. Prod also needs `--confirm <project>`, typed by the person.
- Anything else inside an account: `aws-kit exec --account <name> -- aws <service> <command>`.
- `not_signed_in`: ask the person to run `aws login --profile aws-kit` and sign in as the operator user.
- `aws-kit` not found: ask the person to install it with `bun add -g github:grezxune/aws-kit` and follow the setup in its README.
