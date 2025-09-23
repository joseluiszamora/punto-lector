import prisma from "@/lib/prisma";
import { NextResponse } from "next/server";
import { jsonHeaders, corsHeaders } from "@/lib/cors";

export const runtime = "nodejs";

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function GET() {
  try {
    const categories = await prisma.categories.findMany({
      include: {
        parent: {
          select: { id: true, name: true },
        },
        children: {
          select: { id: true, name: true },
        },
        _count: {
          select: { books: true, children: true },
        },
      },
      orderBy: [{ level: "asc" }, { sort_order: "asc" }, { name: "asc" }],
    });

    return NextResponse.json(categories, { headers: jsonHeaders });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to fetch categories", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, description, color, parent_id, sort_order } = body;

    if (!name) {
      return NextResponse.json(
        { error: "Name is required" },
        { status: 400, headers: jsonHeaders }
      );
    }

    // Calcular el nivel basado en el parent
    let level = 0;
    if (parent_id) {
      const parent = await prisma.categories.findUnique({
        where: { id: parent_id },
        select: { level: true },
      });
      if (parent) {
        level = parent.level + 1;
      }
    }

    const category = await prisma.categories.create({
      data: {
        name,
        description: description || null,
        color: color || null,
        parent_id: parent_id || null,
        level,
        sort_order: sort_order || 0,
      },
      include: {
        parent: {
          select: { id: true, name: true },
        },
        children: {
          select: { id: true, name: true },
        },
        _count: {
          select: { books: true, children: true },
        },
      },
    });

    return NextResponse.json(category, {
      status: 201,
      headers: jsonHeaders,
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to create category", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { id, name, description, color, parent_id, sort_order } = body;

    if (!id || !name) {
      return NextResponse.json(
        { error: "ID and name are required" },
        { status: 400, headers: jsonHeaders }
      );
    }

    // Calcular el nuevo nivel si cambió el parent
    let level = 0;
    if (parent_id) {
      const parent = await prisma.categories.findUnique({
        where: { id: parent_id },
        select: { level: true },
      });
      if (parent) {
        level = parent.level + 1;
      }
    }

    const category = await prisma.categories.update({
      where: { id },
      data: {
        name,
        description: description || null,
        color: color || null,
        parent_id: parent_id || null,
        level,
        sort_order: sort_order || 0,
      },
      include: {
        parent: {
          select: { id: true, name: true },
        },
        children: {
          select: { id: true, name: true },
        },
        _count: {
          select: { books: true, children: true },
        },
      },
    });

    return NextResponse.json(category, { headers: jsonHeaders });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to update category", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json(
        { error: "ID is required" },
        { status: 400, headers: jsonHeaders }
      );
    }

    // Verificar si la categoría tiene hijos
    const categoryWithChildren = await prisma.categories.findUnique({
      where: { id },
      include: {
        children: true,
        _count: { select: { books: true } },
      },
    });

    if (!categoryWithChildren) {
      return NextResponse.json(
        { error: "Category not found" },
        { status: 404, headers: jsonHeaders }
      );
    }

    if (categoryWithChildren.children.length > 0) {
      return NextResponse.json(
        { error: "Cannot delete category with subcategories" },
        { status: 400, headers: jsonHeaders }
      );
    }

    if (categoryWithChildren._count.books > 0) {
      return NextResponse.json(
        { error: "Cannot delete category with associated books" },
        { status: 400, headers: jsonHeaders }
      );
    }

    await prisma.categories.delete({
      where: { id },
    });

    return NextResponse.json(
      { message: "Category deleted successfully" },
      { headers: jsonHeaders }
    );
  } catch (error) {
    const msg = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Failed to delete category", details: msg },
      { status: 500, headers: jsonHeaders }
    );
  }
}
