---
description: DiPro API, controller, and host guidance
applyTo: "**/Controllers/**/*.cs,DiPro.Host/**/*.cs"
---
Golden examples: `DiPro.Wallet/Controllers/Admin/WalletsController.cs` (endpoints), `DiPro.Kernel/Controllers/Common/WalletBaseController.cs` (base), `DiPro.Wallet/ResultExtensions.cs` (result mapping).

## Controllers are transport only
A controller action does exactly three things: build the request record, `await sender.Send(...)`, and `return result.ToActionResult();`. No business logic, no data access, no mapping beyond argument binding. Inject `ISender` through the primary constructor.

## Routing and versioning
- Inherit the module's base controller — `AdminBaseController` or `WalletBaseController` — which carries `[ApiController]`, `[ApiVersion(1)]`, and the route template (`api/wallet/v{version:apiVersion}/[controller]`). Do not repeat those attributes on the derived controller and do not hand-write routes that bypass versioning.
- `Admin/` and `Wallet/` controller folders are different audiences with different permissions. Put an endpoint in the folder matching its caller; never expose an admin query on a customer-facing route.
- Always accept `CancellationToken cancellationToken = default` and pass it to `Send`.

## Contracts
- Request/response shape is a public contract for mobile and admin clients. Changing a field name, type, nullability, or the HTTP status produced is a breaking change requiring explicit approval.
- Authorization belongs on the request record via `[Authorize]` (enforced by `AuthorizationBehavior`), so adding an endpoint that forwards to an existing request inherits its rules. Verify the request is actually protected rather than assuming.
- Before returning a model containing personal or financial fields, check whether the area has an `IPermissionMapper` that strips fields by permission, and route the response through it.

## DiPro.Host
`DiPro.Host` is the composition root: `Program.cs` wires modules, observability, messaging, and the MediatR pipeline in a **specific order** (`AddExceptionHandling().AddAuthorization().AddValidation().AddUnitOfWork()`). Behaviors execute in registration order — do not reorder, and do not add a behavior without approval.

`DiPro.Host/Aggregator` is the only sanctioned place for cross-module composition: queries there fan out to several modules to build a screen-level response. Aggregator code must not reach into another module's Domain or Infrastructure — it sends requests through `ISender`.

Configuration lives in `appsettings*.json` with per-module sections. Never commit real connection strings, tokens, or credentials; development secrets go through user secrets, which `Program.cs` already loads.
