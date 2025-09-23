import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { corsHeaders } from "@/lib/cors";

const prisma = new PrismaClient();

export const runtime = "nodejs";

// GET - Obtener todos los autores
export async function GET() {
  try {
    const authors = await prisma.authors.findMany({
      include: {
        nationality: {
          select: {
            id: true,
            name: true,
            country_code: true,
            flag_url: true,
          },
        },
        _count: {
          select: {
            books: true,
          },
        },
      },
      orderBy: [{ name: "asc" }],
    });

    return NextResponse.json(authors, {
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error fetching authors:", error);
    return NextResponse.json(
      { error: "Error loading authors" },
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

// POST - Crear nuevo autor
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, bio, birth_date, death_date, photo_url, nationality_id } =
      body;

    // Validaciones
    if (!name || name.trim() === "") {
      return NextResponse.json(
        { error: "Author name is required" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Verificar si el autor ya existe
    const existingAuthor = await prisma.authors.findFirst({
      where: {
        name: {
          equals: name.trim(),
          mode: "insensitive",
        },
      },
    });

    if (existingAuthor) {
      return NextResponse.json(
        { error: "An author with this name already exists" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Validar fechas si se proporcionan
    let parsedBirthDate = null;
    let parsedDeathDate = null;

    if (birth_date) {
      parsedBirthDate = new Date(birth_date);
      if (isNaN(parsedBirthDate.getTime())) {
        return NextResponse.json(
          { error: "Invalid birth date format" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    if (death_date) {
      parsedDeathDate = new Date(death_date);
      if (isNaN(parsedDeathDate.getTime())) {
        return NextResponse.json(
          { error: "Invalid death date format" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }

      // Validar que la fecha de muerte sea posterior a la de nacimiento
      if (parsedBirthDate && parsedDeathDate < parsedBirthDate) {
        return NextResponse.json(
          { error: "Death date cannot be before birth date" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    // Verificar que la nacionalidad existe si se proporciona
    if (nationality_id) {
      const nationality = await prisma.nationalities.findUnique({
        where: { id: nationality_id },
      });

      if (!nationality) {
        return NextResponse.json(
          { error: "Invalid nationality selected" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    const newAuthor = await prisma.authors.create({
      data: {
        name: name.trim(),
        bio: bio?.trim() || null,
        birth_date: parsedBirthDate,
        death_date: parsedDeathDate,
        photo_url: photo_url?.trim() || null,
        nationality_id: nationality_id || null,
      },
      include: {
        nationality: {
          select: {
            id: true,
            name: true,
            country_code: true,
            flag_url: true,
          },
        },
        _count: {
          select: {
            books: true,
          },
        },
      },
    });

    return NextResponse.json(newAuthor, {
      status: 201,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error creating author:", error);
    return NextResponse.json(
      { error: "Error creating author" },
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

// PUT - Actualizar autor
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    const { id, name, bio, birth_date, death_date, photo_url, nationality_id } =
      body;

    if (!id) {
      return NextResponse.json(
        { error: "Author ID is required" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    if (!name || name.trim() === "") {
      return NextResponse.json(
        { error: "Author name is required" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Verificar que el autor existe
    const existingAuthor = await prisma.authors.findUnique({
      where: { id },
    });

    if (!existingAuthor) {
      return NextResponse.json(
        { error: "Author not found" },
        {
          status: 404,
          headers: corsHeaders,
        }
      );
    }

    // Verificar que no existe otro autor con el mismo nombre
    const duplicateAuthor = await prisma.authors.findFirst({
      where: {
        name: {
          equals: name.trim(),
          mode: "insensitive",
        },
        id: {
          not: id,
        },
      },
    });

    if (duplicateAuthor) {
      return NextResponse.json(
        { error: "Another author with this name already exists" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Validar fechas
    let parsedBirthDate = null;
    let parsedDeathDate = null;

    if (birth_date) {
      parsedBirthDate = new Date(birth_date);
      if (isNaN(parsedBirthDate.getTime())) {
        return NextResponse.json(
          { error: "Invalid birth date format" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    if (death_date) {
      parsedDeathDate = new Date(death_date);
      if (isNaN(parsedDeathDate.getTime())) {
        return NextResponse.json(
          { error: "Invalid death date format" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }

      if (parsedBirthDate && parsedDeathDate < parsedBirthDate) {
        return NextResponse.json(
          { error: "Death date cannot be before birth date" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    // Verificar nacionalidad si se proporciona
    if (nationality_id) {
      const nationality = await prisma.nationalities.findUnique({
        where: { id: nationality_id },
      });

      if (!nationality) {
        return NextResponse.json(
          { error: "Invalid nationality selected" },
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    const updatedAuthor = await prisma.authors.update({
      where: { id },
      data: {
        name: name.trim(),
        bio: bio?.trim() || null,
        birth_date: parsedBirthDate,
        death_date: parsedDeathDate,
        photo_url: photo_url?.trim() || null,
        nationality_id: nationality_id || null,
      },
      include: {
        nationality: {
          select: {
            id: true,
            name: true,
            country_code: true,
            flag_url: true,
          },
        },
        _count: {
          select: {
            books: true,
          },
        },
      },
    });

    return NextResponse.json(updatedAuthor, {
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error updating author:", error);
    return NextResponse.json(
      { error: "Error updating author" },
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

// DELETE - Eliminar autor
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    if (!id) {
      return NextResponse.json(
        { error: "Author ID is required" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Verificar que el autor existe
    const existingAuthor = await prisma.authors.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            books: true,
          },
        },
      },
    });

    if (!existingAuthor) {
      return NextResponse.json(
        { error: "Author not found" },
        {
          status: 404,
          headers: corsHeaders,
        }
      );
    }

    // Verificar que no tiene libros asociados
    if (existingAuthor._count.books > 0) {
      return NextResponse.json(
        { error: "Cannot delete author: has associated books" },
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    await prisma.authors.delete({
      where: { id },
    });

    return NextResponse.json(
      { message: "Author deleted successfully" },
      { headers: corsHeaders }
    );
  } catch (error) {
    console.error("Error deleting author:", error);
    return NextResponse.json(
      { error: "Error deleting author" },
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
