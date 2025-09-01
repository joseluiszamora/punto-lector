import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Crear algunos libros de ejemplo
  const books = await Promise.all([
    // prisma.books.upsert({
    //   where: { isbn: "978-84-376-0494-7" },
    //   update: {},
    //   create: {
    //     title: "Cien años de soledad",
    //     author: "Gabriel García Márquez",
    //     isbn: "978-84-376-0494-7",
    //     summary:
    //       "Una obra maestra del realismo mágico que narra la historia de la familia Buendía.",
    //     language: "es",
    //     genres: ["Realismo mágico", "Literatura latinoamericana"],
    //     published_at: new Date("1967-05-30"),
    //   },
    // }),
    // prisma.books.upsert({
    //   where: { isbn: "978-84-376-0495-4" },
    //   update: {},
    //   create: {
    //     title: "El amor en los tiempos del cólera",
    //     author: "Gabriel García Márquez",
    //     isbn: "978-84-376-0495-4",
    //     summary:
    //       "Una historia de amor que transcurre a lo largo de más de cincuenta años.",
    //     language: "es",
    //     genres: ["Romance", "Literatura latinoamericana"],
    //     published_at: new Date("1985-12-01"),
    //   },
    // }),
    // prisma.books.upsert({
    //   where: { isbn: "978-84-376-0496-1" },
    //   update: {},
    //   create: {
    //     title: "La casa de los espíritus",
    //     author: "Isabel Allende",
    //     isbn: "978-84-376-0496-1",
    //     summary: "La saga de una familia a lo largo de cuatro generaciones.",
    //     language: "es",
    //     genres: ["Realismo mágico", "Drama familiar"],
    //     published_at: new Date("1982-01-01"),
    //   },
    // }),
    // prisma.books.upsert({
    //   where: { isbn: "978-84-376-0497-8" },
    //   update: {},
    //   create: {
    //     title: "Rayuela",
    //     author: "Julio Cortázar",
    //     isbn: "978-84-376-0497-8",
    //     summary:
    //       "Una novela experimental que se puede leer de múltiples formas.",
    //     language: "es",
    //     genres: ["Literatura experimental", "Literatura argentina"],
    //     published_at: new Date("1963-06-28"),
    //   },
    // }),
  ]);

  console.log(`✅ Created ${books.length} books`);
  console.log("Seed completed successfully!");
}

main()
  .catch((e) => {
    console.error("❌ Seeding failed:");
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
