# swift-secp256k1 — SEO Adjustments Worklist

**Source:** Ahrefs Site Audit, project `21.dev` (ID 9842697), crawl date 2026-05-25.
**Scope:** Pages under `https://docs.21.dev/documentation/p256k/` that are indexed by the registry's `indexablePages` allowlist (`Resources/docs-21-dev/external-archives.json`) but flagged by Ahrefs for SEO content-quality issues.
**Upstream repo:** [21-DOT-DEV/swift-secp256k1](https://github.com/21-DOT-DEV/swift-secp256k1)

Fixes here land as PRs in the upstream `swift-secp256k1` Swift package — `///` doc-comment edits on the listed Swift symbols. After upstream merges and tags a new release, bump `external-archives.json`'s `p256k` and `zkp` `tag` + `sha256` and re-run `swift run util agent-directive audit` to confirm the issues clear.

---

## How to map each URL to a Swift source location

The URL path mirrors the DocC catalog structure:

| URL fragment | Swift identifier |
|---|---|
| `documentation/p256k/<Type>` | top-level type `<Type>` (e.g., `SharedSecret`, `Int256`) |
| `documentation/p256k/<Type>/<member>` | `<Type>.<member>` (e.g., `UInt256.addMod(_:modulus:)`) |
| `documentation/p256k/p256k/<Namespace>` | `P256K.<Namespace>` (e.g., `P256K.Signing`) |
| `documentation/p256k/p256k/<Namespace>/<Type>` | `P256K.<Namespace>.<Type>` (e.g., `P256K.Schnorr.PrivateKey`) |
| `documentation/p256k/p256k/<Namespace>/<Type>/<member>` | `P256K.<Namespace>.<Type>.<member>` |
| `documentation/p256k/<slug>` (no nested path) | An article — `.md` file under `Sources/P256K/P256K.docc/` matching the slug |

`grep -rn 'fooMember' Sources/P256K` in the upstream repo locates the `///` block to edit.

---

## Section 1 — Meta descriptions to **compact** (46 entries, Warning, indexable)

Each entry below has a current meta description >150 chars with an embedded `doc://P256K/documentation/P256K/...` DocC link reference. The DocC link reference renders cleanly as an `<a>` in HTML but inflates the meta-description text seen by crawlers. **Fix:** rewrite the `///` summary line as plain prose without `doc://` references (push cross-references into the `## Discussion` section instead, which isn't surfaced as `<meta description>`).

| URL (suffix after `https://docs.21.dev/`) | Swift symbol | Chars |
|---|---|---|
| `documentation/p256k/p256k/musig/publickey/isvalidsignature(_:publickey:nonce:for:)/` | `P256K.MuSig.PublicKey.isValidSignature(_:publicKey:nonce:for:)` | 229 |
| `documentation/p256k/p256k/keyagreement/publickey/` | `P256K.KeyAgreement.PublicKey` | 210 |
| `documentation/p256k/p256k/schnorr/schnorrsignature/` | `P256K.Schnorr.SchnorrSignature` | 231 |
| `documentation/p256k/p256k/schnorr/` | `P256K.Schnorr` | 288 |
| `documentation/p256k/p256k/musig/aggregatesignatures(_:)/` | `P256K.MuSig.aggregateSignatures(_:)` | 167 |
| `documentation/p256k/p256k/recovery/ecdsasignature/normalize/` | `P256K.Recovery.ECDSASignature.normalize` | 167 |
| `documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:xonlykeyaggregate:)/` | `P256K.Schnorr.PrivateKey.partialSignature(for:pubnonce:secureNonce:publicNonceAggregate:xonlyKeyAggregate:)` | 369 |
| `documentation/p256k/p256k/keyagreement/` | `P256K.KeyAgreement` | 360 |
| `documentation/p256k/p256k/signing/ecdsasignature/` | `P256K.Signing.ECDSASignature` | 176 |
| `documentation/p256k/p256k/keyagreement/xonlykey/parity/` | `P256K.KeyAgreement.XonlyKey.parity` | 180 |
| `documentation/p256k/p256k/recovery/ecdsacompactsignature/` | `P256K.Recovery.ECDSACompactSignature` | 205 |
| `documentation/p256k/p256k/recovery/ecdsasignature/` | `P256K.Recovery.ECDSASignature` | 173 |
| `documentation/p256k/int256/` | `Int256` | 226 |
| `documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:publickeyaggregate:)/` | `P256K.Schnorr.PrivateKey.partialSignature(for:pubnonce:secureNonce:publicNonceAggregate:publicKeyAggregate:)` | 261 |
| `documentation/p256k/p256k/schnorr/privatekey/negation/` | `P256K.Schnorr.PrivateKey.negation` | 186 |
| `documentation/p256k/p256k/keyagreement/privatekey/` | `P256K.KeyAgreement.PrivateKey` | 191 |
| `documentation/p256k/p256k/musig/nonce/` | `P256K.MuSig.Nonce` | 169 |
| `documentation/p256k/p256k/schnorr/privatekey/add(_:)/` | `P256K.Schnorr.PrivateKey.add(_:)` | 242 |
| `documentation/p256k/p256k/musig/aggregate(_:)/` | `P256K.MuSig.aggregate(_:)` | 275 |
| `documentation/p256k/sha256/taggedhash(tag:data:)/` | `SHA256.taggedHash(tag:data:)` | 185 |
| `documentation/p256k/sha256/` | `SHA256` | 344 |
| `documentation/p256k/p256k/signing/publickey/combine(_:format:)/` | `P256K.Signing.PublicKey.combine(_:format:)` | 257 |
| `documentation/p256k/p256k/recovery/` | `P256K.Recovery` | 335 |
| `documentation/p256k/p256k/signing/privatekey/multiply(_:)/` | `P256K.Signing.PrivateKey.multiply(_:)` | 207 |
| `documentation/p256k/p256k/signing/privatekey/add(_:)/` | `P256K.Signing.PrivateKey.add(_:)` | 260 |
| `documentation/p256k/p256k/schnorr/partialsignature/` | `P256K.Schnorr.PartialSignature` | 297 |
| `documentation/p256k/p256k/recovery/publickey/` | `P256K.Recovery.PublicKey` | 203 |
| `documentation/p256k/` | `documentation/p256k` (module landing — `Sources/P256K/P256K.docc/P256K.md`) | 188 |
| `documentation/p256k/p256k/musig/nonceresult/` | `P256K.MuSig.NonceResult` | 215 |
| `documentation/p256k/p256k/signing/publickey/add(_:format:)/` | `P256K.Signing.PublicKey.add(_:format:)` | 206 |
| `documentation/p256k/p256k/signing/xonlykey/` | `P256K.Signing.XonlyKey` | 275 |
| `documentation/p256k/p256k/schnorr/publickey/` | `P256K.Schnorr.PublicKey` | 225 |
| `documentation/p256k/p256k/signing/privatekey/` | `P256K.Signing.PrivateKey` | 179 |
| `documentation/p256k/p256k/musig/publickey/add(_:format:)/` | `P256K.MuSig.PublicKey.add(_:format:)` | 266 |
| `documentation/p256k/p256k/musig/publickey/` | `P256K.MuSig.PublicKey` | 207 |
| `documentation/p256k/p256k/schnorr/xonlykey/add(_:)/` | `P256K.Schnorr.XonlyKey.add(_:)` | 243 |
| `documentation/p256k/foundation/data/copytounsafemutablebytes(of:)/` | `Foundation.Data.copyToUnsafeMutableBytes(of:)` (extension) | 183 |
| `documentation/p256k/p256k/signing/publickey/` | `P256K.Signing.PublicKey` | 190 |
| `documentation/p256k/p256k/signing/` | `P256K.Signing` | 279 |
| `documentation/p256k/p256k/musig/aggregatesignature/` | `P256K.MuSig.AggregateSignature` | 262 |
| `documentation/p256k/p256k/musig/` | `P256K.MuSig` | 314 |
| `documentation/p256k/ellipticcurvediffiehellman/` | Article — `Sources/P256K/P256K.docc/EllipticCurveDiffieHellman.md` | 187 |
| `documentation/p256k/p256k/schnorr/privatekey/` | `P256K.Schnorr.PrivateKey` | 191 |
| `documentation/p256k/uint256/` | `UInt256` | 190 |
| `documentation/p256k/p256k/musig/xonlykey/` | `P256K.MuSig.XonlyKey` | 196 |
| `documentation/p256k/p256k/musig/xonlykey/add(_:)/` | `P256K.MuSig.XonlyKey.add(_:)` | 217 |

**Recommended template** for the rewrite:
> Original: `secp256k1 BIP-340 Schnorr private key for signing messages with \`\`doc://P256K/documentation/P256K/P256K/Schnorr/SchnorrSignature\`\` and for deriving the x-only public key used in verification.`
>
> Suggested: `Secp256k1 BIP-340 Schnorr private key. Signs messages, produces \`SchnorrSignature\`, and derives the x-only public key for verification.`
>
> (Move the full cross-reference into the `## Discussion` section underneath.)

---

## Section 2 — Meta descriptions to **extend** (27 entries, Warning, indexable)

Each entry has a current meta description <120 chars. **Fix:** extend the `///` summary sentence with one more clause of context (e.g., the type's role, the upstream C function name, the BIP/standard it implements). Target 150–160 chars for the summary so DocC's emitted `<meta description>` lands in the SEO sweet spot.

| URL (suffix) | Swift symbol | Chars | Current text |
|---|---|---|---|
| `documentation/p256k/p256k/signing/privatekey/init(datarepresentation:format:)/` | `P256K.Signing.PrivateKey.init(dataRepresentation:format:)` | 70 | Creates a secp256k1 private key for signing from a 32-byte raw scalar. |
| `documentation/p256k/p256k/musig/publickey/init(datarepresentation:format:cache:)/` | `P256K.MuSig.PublicKey.init(dataRepresentation:format:cache:)` | 97 | Creates a MuSig aggregate public key from serialized bytes and a preserved key aggregation cache. |
| `documentation/p256k/serializingkeys/` | Article — `Sources/P256K/P256K.docc/SerializingKeys.md` (⚠ deleted upstream in 0.23.2; remove from registry) | 74 | Import and export keys in raw bytes, PEM, DER, and other standard formats. |
| `documentation/p256k/p256k/recovery/privatekey/init(datarepresentation:format:)/` | `P256K.Recovery.PrivateKey.init(dataRepresentation:format:)` | 78 | Creates a secp256k1 recoverable-signing private key from a 32-byte raw scalar. |
| `documentation/p256k/p256k/signing/publickey/init(x963representation:)/` | `P256K.Signing.PublicKey.init(x963Representation:)` | 65 | Creates a secp256k1 public key from an ANSI X9.63 representation. |
| `documentation/p256k/secp256k1error/underlyingcryptoerror/` | `secp256k1Error.underlyingCryptoError` | 86 | A libsecp256k1 C function returned `0`, indicating the cryptographic operation failed. |
| `documentation/p256k/uint256/addmod(_:modulus:)/` | `UInt256.addMod(_:modulus:)` | 35 | Returns `(self + other) % modulus`. |
| `documentation/p256k/p256k/schnorr/privatekey/publickey/` | `P256K.Schnorr.PrivateKey.publicKey` | 93 | The full secp256k1 public key derived from this private key, in uncompressed form (65 bytes). |
| `documentation/p256k/keyformats/` | Article — `Sources/P256K/P256K.docc/KeyFormats.md` (⚠ deleted upstream in 0.23.2; remove from registry) | 83 | Understand why secp256k1 has multiple key representations and when to use each one. |
| `documentation/p256k/sharedsecret/==(_:_:)-7g0c5/` | `SharedSecret.==(_:_:)` (⚠ flagged stale in audit — already removed from registry) | 85 | Determines whether a shared secret is equivalent to a collection of contiguous bytes. |
| `documentation/p256k/p256k/schnorr/nonce/init(datarepresentation:)/` | `P256K.Schnorr.Nonce.init(dataRepresentation:)` | 64 | Creates a public nonce from a 66-byte serialized representation. |
| `documentation/p256k/uint256/mulmod(_:modulus:)/` | `UInt256.mulMod(_:modulus:)` | 35 | Returns `(self * other) % modulus`. |
| `documentation/p256k/swift/string/bytes/` | `Swift.String.bytes` (extension) | 67 | The bytes decoded from this hex string, lowercased before decoding. |
| `documentation/p256k/p256k/musig/nonce/generate(sessionid:secretkey:publickey:msg32:extrainput32:)/` | `P256K.MuSig.Nonce.generate(sessionID:secretKey:publicKey:msg32:extraInput32:)` | 95 | Generates a fresh nonce pair for one MuSig2 signing session using a caller-supplied session ID. |
| `documentation/p256k/foundation/data/compactsizeprefix/` | `Foundation.Data.compactSizePrefix` (extension) | 84 | The data prefixed with a Bitcoin-style compact-size integer encoding the byte count. |
| `documentation/p256k/p256k/schnorr/privatekey/init(datarepresentation:)/` | `P256K.Schnorr.PrivateKey.init(dataRepresentation:)` | 66 | Creates a secp256k1 Schnorr private key from a 32-byte raw scalar. |
| `documentation/p256k/recoveringpublickeys/` | Article — `Sources/P256K/P256K.docc/RecoveringPublicKeys.md` | 77 | Recover an ECDSA public key from a recoverable signature and its recovery ID. |
| `documentation/p256k/foundation/contiguousbytes/bytes/` | `Foundation.ContiguousBytes.bytes` (extension) | 96 | The raw bytes of this value as a `[UInt8]` array, equivalent to `withUnsafeBytes { Array($0) }`. |
| `documentation/p256k/p256k/musig/nonce/generate(secretkey:publickey:msg32:extrainput32:)/` | `P256K.MuSig.Nonce.generate(secretKey:publicKey:msg32:extraInput32:)` | 95 | Generates a fresh nonce pair for one MuSig2 signing session using a random 133-byte session ID. |
| `documentation/p256k/p256k/signing/privatekey/init(_:format:)/` | `P256K.Signing.PrivateKey.init(_:format:)` | 70 | Creates a secp256k1 private key for signing from a `UInt256` constant. |
| `documentation/p256k/p256k/keyagreement/publickey/init(datarepresentation:format:)/` | `P256K.KeyAgreement.PublicKey.init(dataRepresentation:format:)` | 58 | Creates a secp256k1 ECDH public key from serialized bytes. |
| `documentation/p256k/p256k/schnorr/xonlykey/` | `P256K.Schnorr.XonlyKey` | 83 | The corresponding x-only public key for the secp256k1 curve, as defined by BIP-340. |
| `documentation/p256k/secp256k1error/incorrectkeysize/` | `secp256k1Error.incorrectKeySize` | 49 | A key was deserialized with the wrong byte count. |
| `documentation/p256k/p256k/keyagreement/publickey/init(x963representation:)/` | `P256K.KeyAgreement.PublicKey.init(x963Representation:)` | 70 | Creates a secp256k1 ECDH public key from an ANSI X9.63 representation. |
| `documentation/p256k/p256k/keyagreement/privatekey/init(datarepresentation:format:)/` | `P256K.KeyAgreement.PrivateKey.init(dataRepresentation:format:)` | 63 | Creates a secp256k1 ECDH private key from a 32-byte raw scalar. |
| `documentation/p256k/secp256k1error/incorrectparametersize/` | `secp256k1Error.incorrectParameterSize` | 50 | A function argument had the wrong number of bytes. |
| `documentation/p256k/securityconsiderations/` | Article — `Sources/P256K/P256K.docc/SecurityConsiderations.md` | 91 | Understand the security properties of P256K and how to avoid common cryptographic pitfalls. |

**Recommended template** for the extension:
> Original: `/// Returns \`(self + other) % modulus\`.`
>
> Suggested: `/// Computes \`(self + other) % modulus\` for 256-bit modular addition. Used for arithmetic in the secp256k1 finite field where the modulus is the curve order \`n\`.`

---

## Section 3 — Titles flagged for length (44 entries) — **informational only**

DocC always uses the bare Swift symbol name as the page `<title>` (e.g., `parity`, `cache`, `add(_:)`). This cannot be improved by editing `///` doc comments — the only ways to fix it would be:

1. **Rename the Swift symbol** (impractical — breaks API).
2. **Post-process HTML titles at build time** (out of scope for the upstream package; would be implemented in `21-DOT-DEV/websites` as a new `util` step that injects namespace context, e.g., `"parity"` → `"parity — P256K.Schnorr.XonlyKey · docs.21.dev"`).

Listed here for upstream awareness and as a future post-processor candidate. **No action requested upstream.**

### Title too short — 42 pages

`documentation/p256k/p256k/signing/xonlykey/parity/`, `documentation/p256k/p256k/recovery/ecdsacompactsignature/recoveryid/`, `documentation/p256k/p256k/context/`, `documentation/p256k/p256k/schnorr/`, `documentation/p256k/p256k/recovery/ecdsasignature/normalize/`, `documentation/p256k/p256k/musig/xonlykey/cache/`, `documentation/p256k/p256k/keyagreement/xonlykey/parity/`, `documentation/p256k/int256/`, `documentation/p256k/p256k/schnorr/privatekey/negation/`, `documentation/p256k/p256k/schnorr/privatekey/publickey/`, `documentation/p256k/p256k/schnorr/privatekey/add(_:)/`, `documentation/p256k/p256k/musig/aggregate(_:)/`, `documentation/p256k/sha256/`, `documentation/p256k/p256k/recovery/`, `documentation/p256k/keyformats/`, `documentation/p256k/p256k/signing/privatekey/multiply(_:)/`, `documentation/p256k/p256k/signing/privatekey/add(_:)/`, `documentation/p256k/sharedsecret/==(_:_:)-7g0c5/`, `documentation/p256k/p256k/format/`, `documentation/p256k/swift/string/bytes/`, `documentation/p256k/`, `documentation/p256k/p256k/musig/xonlykey/parity/`, `documentation/p256k/p256k/schnorr/privatekey/init()/`, `documentation/p256k/p256k/signing/publickey/add(_:format:)/`, `documentation/p256k/p256k/recovery/privatekey/init(format:)/`, `documentation/p256k/foundation/contiguousbytes/bytes/`, `documentation/p256k/tweakingkeys/`, `documentation/p256k/p256k/context/create()/`, `documentation/p256k/p256k/musig/publickey/add(_:format:)/`, `documentation/p256k/p256k/schnorr/xonlykey/add(_:)/`, `documentation/p256k/swift/string/init(bytes:)/`, `documentation/p256k/p256k/musig/publickey/xonly/`, `documentation/p256k/p256k/signing/`, `documentation/p256k/p256k/signing/privatekey/init(format:)/`, `documentation/p256k/p256k/schnorr/xonlykey/cache/`, `documentation/p256k/p256k/musig/`, `documentation/`, `documentation/p256k/sha256/hash(data:)/`, `documentation/p256k/uint256/`, `documentation/p256k/p256k/`, `documentation/p256k/p256k/signing/publickey/xonly/`, `documentation/p256k/p256k/musig/xonlykey/add(_:)/`

### Title too long — 2 pages

`documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:xonlykeyaggregate:)/`, `documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:publickeyaggregate:)/`

---

## Tracking & follow-up

After upstream `swift-secp256k1` ships fixes:

1. Bump `tag` + `sha256` in `Resources/docs-21-dev/external-archives.json` for both `p256k` and `zkp` entries.
2. Re-run the local build pipeline (`xcrun docc merge` + `util canonical fix` + `util links rewrite` + `util agent-directive inject` + `util agent-directive audit`).
3. Confirm with a fresh Ahrefs Site Audit crawl that the issue counts drop. Project ID `9842697`; the next crawl runs on the project's configured schedule.
4. If the title-too-short/long category still flags pages after upstream improvements, evaluate whether to build the in-repo HTML title-enhancement post-processor (would be a new `util` subcommand, e.g., `util titles enhance`).

---

## Note — docs.21.dev SPA shell at `/documentation/`

The Ahrefs crawl flagged the docs root (`https://docs.21.dev/documentation/`) for:
- Missing `<meta name="description">`
- Low word count
- Orphan (Warning level — DocC sub-modules link to it via breadcrumbs)

**Not addressed in this repo by design.** docs.21.dev is a JS-rendered SPA. DocC's runtime JS injects a per-route `<meta name="description">` (e.g., for `/documentation/p256k` it injects the P256K module's authored abstract) and renders the page body from the sidecar JSON. Injecting a static description in the build pipeline would create a divergence between what JS-off crawlers see and what JS-on crawlers see for the same canonical URL, sending mixed signals to indexers.

These flags are the documented cost of a JS-rendered SPA. The right long-term fix is upstream in DocC itself — adding an SSR-style static fallback that matches the runtime-injected description. Not in scope for this worklist.
