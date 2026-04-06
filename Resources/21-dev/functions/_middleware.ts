import { resolveRedirect } from "./logic.js";

export async function onRequest(context: EventContext<unknown, string, unknown>) {
  const url = new URL(context.request.url);

  const result = resolveRedirect(url.hostname);
  if (result.redirect) {
    url.hostname = result.target;
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  try {
    return await context.next();
  } catch (err) {
    return new Response("Internal Server Error", { status: 500 });
  }
}