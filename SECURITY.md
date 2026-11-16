# Security policy

## Supported branches

Security fixes are provided for the following branches:

| Branch | Status |
| --- | --- |
| `wrynose` | Supported |

## Reporting a vulnerability

This policy covers `meta-imx-secure`, including its recipes, patches, scripts and security configuration for NXP i.MX boards.

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately by email to [info@embetrix.com](mailto:info@embetrix.com).

Include:

- A description of the issue and its impact
- Steps to reproduce or a proof-of-concept
- Affected version, branch, or commit
- Board, SoC, silicon revision and security profile (`dev` or `prod`)
- Your name or handle for credit (optional)

## Scope

Report issues in upstream components to their maintainers:

- NXP i.MX Boot ROM and firmware, including EdgeLock Enclave firmware
- U-Boot, TF-A, OP-TEE, the Linux kernel and NXP SPSDK
- OpenEmbedded Core and the other [layer dependencies](README.md#layer-dependencies)

Issues caused by this layer's patches or integration are in scope. If you are unsure where an issue belongs, report it privately using the email above.

Out of scope:

- Physical attacks such as bus probing, glitching and side-channel attacks
- Misuse caused by ignoring documented warnings, such as losing signing keys after programming OTP fuses
