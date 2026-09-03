# Manual

> **Not translated, by decision.** This project is monolingual in pt-BR. The source of
> truth is [`docs/pt-br/manual/index.md`](../../pt-br/manual/index.md), which itself
> points to the real documentation: the runbook in [`docs/guias/`](../../guias/).

The filename is kept so the parity check between language subtrees stays empty:

```
diff <(cd docs/pt-br && find . -type f | sort) <(cd docs/en-us && find . -type f | sort)
```
