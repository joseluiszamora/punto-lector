import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { PrismaClient } from "@prisma/client";

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3001;
const prisma = new PrismaClient();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get("/", (req, res) => {
  res.json({
    message: "Punto Lector API",
    version: "1.0.0",
    status: "running",
  });
});

app.get("/health", async (req, res) => {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: "healthy", database: "connected" });
  } catch (error) {
    res.status(500).json({
      status: "unhealthy",
      database: "disconnected",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// Books routes
app.get("/api/books", async (req, res) => {
  try {
    const { search, author, limit = "50" } = req.query;

    let where: any = {};
    if (search) {
      where.OR = [
        { title: { contains: search as string, mode: "insensitive" } },
        { author: { contains: search as string, mode: "insensitive" } },
      ];
    }
    if (author) {
      where.author = { contains: author as string, mode: "insensitive" };
    }

    const books = await prisma.books.findMany({
      where,
      take: parseInt(limit as string),
      orderBy: { title: "asc" },
    });

    res.json(books);
  } catch (error) {
    res.status(500).json({
      error: "Failed to fetch books",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// Stores routes
app.get("/api/stores", async (req, res) => {
  try {
    const { active = "true" } = req.query;

    const stores = await prisma.stores.findMany({
      where: {
        active: active === "true",
      },
      orderBy: { name: "asc" },
    });

    res.json(stores);
  } catch (error) {
    res.status(500).json({
      error: "Failed to fetch stores",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// Listings routes
app.get("/api/listings", async (req, res) => {
  try {
    const { store_id, book_id, active = "true" } = req.query;

    let where: any = { active: active === "true" };
    if (store_id) where.store_id = store_id as string;
    if (book_id) where.book_id = book_id as string;

    const listings = await prisma.listings.findMany({
      where,
      include: {
        stores: { select: { name: true, city: true } },
        books: { select: { title: true, author: true } },
      },
      orderBy: { created_at: "desc" },
    });

    res.json(listings);
  } catch (error) {
    res.status(500).json({
      error: "Failed to fetch listings",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// Error handling
app.use(
  (
    error: Error,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Unhandled error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
);

// Graceful shutdown
process.on("SIGINT", async () => {
  console.log("Shutting down gracefully...");
  await prisma.$disconnect();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  console.log("Shutting down gracefully...");
  await prisma.$disconnect();
  process.exit(0);
});

// Start server
app.listen(port, () => {
  console.log(`🚀 Punto Lector API running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
});
