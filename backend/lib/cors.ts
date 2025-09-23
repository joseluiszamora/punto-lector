export const corsHeaders: Record<string, string> = {
  "access-control-allow-origin": process.env.CORS_ORIGIN || "*",
  "access-control-allow-methods": "GET,OPTIONS",
  "access-control-allow-headers": "content-type",
};

export const jsonHeaders: Record<string, string> = {
  "content-type": "application/json; charset=utf-8",
  ...corsHeaders,
};
