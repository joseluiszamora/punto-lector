import prisma from "@/lib/prisma";
import { NextResponse } from "next/server";
import { jsonHeaders, corsHeaders } from "@/lib/cors";

export const runtime = "nodejs";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const active = (searchParams.get("active") ?? "true") === "true";

    const stores = await prisma.stores.findMany({
      where: { active },
      orderBy: { name: "asc" },
    });

    return NextResponse.json(stores, { headers: jsonHeaders });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to fetch stores", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}
