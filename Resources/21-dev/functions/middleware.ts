export async function onRequest(context: EventContext<unknown, string, unknown>) {
  const url = new URL(context.request.url);

  // Redirect pages.dev traffic to custom domain
  if (url.hostname.endsWith("pages.dev")) {
    url.hostname = "21.dev";
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  // Serve request with error handling
  try {
    return await context.next();
  } catch (err) {
    return new Response("Internal Server Error", { status: 500 });
  }
}