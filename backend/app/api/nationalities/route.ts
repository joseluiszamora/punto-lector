import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { corsHeaders } from "@/lib/cors";

const prisma = new PrismaClient();

export const runtime = "nodejs";

// GET - Obtener todas las nacionalidades
export async function GET() {
  try {
    const nationalities = await prisma.nationalities.findMany({
      orderBy: [{ name: "asc" }],
    });

    return NextResponse.json(nationalities, {
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error fetching nationalities:", error);
    return NextResponse.json(
      { error: "Error loading nationalities" },
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

// OPTIONS - Para CORS
export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}
