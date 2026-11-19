# Security Policy

## Reporting a Vulnerability

To report a security vulnerability in the 21.dev sites or this repository, either:
* send an email to `security@21.dev`, or
* use [GitHub Security Advisories](https://github.com/21-DOT-DEV/websites/security/advisories).

**Do not file a public issue.**

When reporting, please include:
* A description of the vulnerability
* Steps to reproduce or a proof of concept
* Potential impact assessment

We will acknowledge receipt within 7 days and provide an initial assessment as soon as possible.

## Scope

This policy covers:
* `21.dev` and `docs.21.dev` — the deployed static sites, their Cloudflare
  Pages configuration (`_headers`, `_redirects`, `functions/`), and the
  content they serve
* this repository — the site generators, shared libraries (`DesignSystem`,
  `UtilLib`, `SchemaLib`, `SiteIdentity`), and CI workflows

Vulnerabilities in the packages themselves should be reported through each
package's own policy:
* **swift-secp256k1**: [SECURITY.md](https://github.com/21-DOT-DEV/swift-secp256k1/blob/main/SECURITY.md)
* other `21-DOT-DEV` package repositories: see that repository's `SECURITY.md`

Vulnerabilities in the hosting platform should be reported directly to its
vendor:
* **Cloudflare Pages/Workers**: [Cloudflare's disclosure program](https://www.cloudflare.com/disclosure/)

## Published Security Advisories

Published advisories follow the fixed format used across `21-DOT-DEV`
repositories — see the [swift-secp256k1 security policy](https://github.com/21-DOT-DEV/swift-secp256k1/blob/main/SECURITY.md)
for the field conventions (Summary, Details, PoC, Impact, Patches, Workarounds,
References). Reporters are credited by name in the advisory body and in
GitHub's credits field.
