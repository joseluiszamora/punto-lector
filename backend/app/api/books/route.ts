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
    const search = searchParams.get("search") || undefined;
    const author = searchParams.get("author") || undefined;
    const limit = parseInt(searchParams.get("limit") || "50", 10);

    const where: any = {};
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { author: { contains: search, mode: "insensitive" } },
      ];
    }
    if (author) {
      where.author = { contains: author, mode: "insensitive" };
    }

    const books = await prisma.books.findMany({
      where,
      take: limit,
      orderBy: { title: "asc" },
    });

    return NextResponse.json(books, { headers: jsonHeaders });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to fetch books", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}
