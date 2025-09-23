import prisma from "@/lib/prisma";
import { NextResponse } from "next/server";
import { jsonHeaders, corsHeaders } from "@/lib/cors";

export const runtime = "nodejs";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function GET() {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return NextResponse.json(
      { status: "healthy", database: "connected" },
      { headers: jsonHeaders }
    );
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { status: "unhealthy", database: "disconnected", error: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}
