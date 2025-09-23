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
    const store_id = searchParams.get("store_id") || undefined;
    const book_id = searchParams.get("book_id") || undefined;
    const active = (searchParams.get("active") ?? "true") === "true";

    const where: any = { active };
    if (store_id) where.store_id = store_id;
    if (book_id) where.book_id = book_id;

    const listings = await prisma.listings.findMany({
      where,
      include: {
        stores: { select: { name: true, city: true } },
        books: { select: { title: true, author: true } },
      },
      orderBy: { created_at: "desc" },
    });

    return NextResponse.json(listings, { headers: jsonHeaders });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to fetch listings", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}
