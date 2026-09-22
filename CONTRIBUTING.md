# Contributing

Open an issue before changing module contracts or version floors. Keep changes focused and never include credentials, account identifiers, state, plan files, or production variable files.

```bash
terraform fmt -check -recursive
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=modules/networking init -backend=false
terraform -chdir=modules/networking test
trivy config .
```

Pull requests must not add an automated apply stage. Any real deployment requires a reviewed saved plan and explicit approval.
