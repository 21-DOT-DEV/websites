/**
 * Determines whether a hostname should be redirected to the custom domain.
 * @param {string} hostname
 * @returns {{ redirect: boolean, target: string }}
 */
export function resolveRedirect(hostname) {
  if (hostname === "21-dev.pages.dev") {
    return { redirect: true, target: "21.dev" };
  }
  return { redirect: false, target: hostname };
}
