// Documentation-only executable target for swift-secp256k1
// This target exists solely to allow swift-docc-plugin to generate
// combined documentation for the swift-secp256k1 package products.
//
// Per Project Constitution v1.1.0:
// Documentation-only targets are exempt from the zero-dependency principle
// and may import external packages for documentation generation purposes.

import P256K
import ZKP
import libsecp256k1
import libsecp256k1_zkp

// This executable does not run in production.
// It exists only as a dependency anchor for DocC documentation generation.
print("This target is for documentation generation only and should not be executed.")
