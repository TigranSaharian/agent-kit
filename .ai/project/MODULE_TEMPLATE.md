# <Project name> module / feature template

> Template. Describe the standard layout for adding a module or feature, so agents copy the pattern instead of inventing one. It is guidance, not a code generator.

## Standard project set

| Project / folder | Responsibility | May reference |
|---|---|---|
| `<Name.Domain>` | <entities, value objects, domain events> | <nothing / shared kernel> |
| `<Name.Application>` | <use cases, handlers, validation> | <Domain> |
| `<Name.Infrastructure>` | <persistence, external clients, messaging> | <Application, Domain> |
| `<Name.Api>` | <controllers / endpoints> | <Application> |
| `<Name.Tests>` | <tests> | <all of the above> |

## Folder layout

```
<Module>/
  <Aggregate>/
    Entities/
    ...
```

## Dependency boundaries

- <Rule, for example: no module references another module's Domain or Infrastructure project>
- <Rule, for example: cross-module communication goes through published contracts>

## Module creation checklist

- [ ] <Create projects and add them to the solution>
- [ ] <Register the module in the host>
- [ ] <Add tests following the existing pattern>

## Reference modules

- `<path>`: the closest example to copy from, and why
