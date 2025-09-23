import Link from "next/link";

export default function Home() {
  return (
    <div>
      <h1 style={{ marginBottom: "0.5rem", color: "#343a40" }}>
        Dashboard - Punto Lector Admin
      </h1>
      <p style={{ color: "#6c757d", marginBottom: "2rem" }}>
        Panel de administración para gestionar libros, autores y categorías
      </p>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
          gap: "1.5rem",
          marginBottom: "2rem",
        }}
      >
        <div
          style={{
            padding: "1.5rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>📚 Libros</h3>
          <p
            style={{
              margin: "0 0 1rem 0",
              color: "#6c757d",
              fontSize: "0.9rem",
            }}
          >
            Gestionar el catálogo de libros disponibles
          </p>
          <Link
            href="/admin/books"
            style={{
              display: "inline-block",
              padding: "0.5rem 1rem",
              backgroundColor: "#007bff",
              color: "white",
              textDecoration: "none",
              borderRadius: "0.25rem",
              fontSize: "0.875rem",
            }}
          >
            Ver Libros
          </Link>
        </div>

        <div
          style={{
            padding: "1.5rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>✍️ Autores</h3>
          <p
            style={{
              margin: "0 0 1rem 0",
              color: "#6c757d",
              fontSize: "0.9rem",
            }}
          >
            Administrar información de autores
          </p>
          <Link
            href="/admin/authors"
            style={{
              display: "inline-block",
              padding: "0.5rem 1rem",
              backgroundColor: "#28a745",
              color: "white",
              textDecoration: "none",
              borderRadius: "0.25rem",
              fontSize: "0.875rem",
            }}
          >
            Ver Autores
          </Link>
        </div>

        <div
          style={{
            padding: "1.5rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
            🏷️ Categorías
          </h3>
          <p
            style={{
              margin: "0 0 1rem 0",
              color: "#6c757d",
              fontSize: "0.9rem",
            }}
          >
            Organizar categorías y subcategorías
          </p>
          <Link
            href="/admin/categories"
            style={{
              display: "inline-block",
              padding: "0.5rem 1rem",
              backgroundColor: "#ffc107",
              color: "#212529",
              textDecoration: "none",
              borderRadius: "0.25rem",
              fontSize: "0.875rem",
            }}
          >
            Ver Categorías
          </Link>
        </div>
      </div>

      <div
        style={{
          padding: "1.5rem",
          backgroundColor: "#e9ecef",
          borderRadius: "0.5rem",
          border: "1px solid #dee2e6",
        }}
      >
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          🔗 Enlaces API
        </h3>
        <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
          <a
            href="/health"
            target="_blank"
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "white",
              color: "#007bff",
              textDecoration: "none",
              borderRadius: "0.25rem",
              border: "1px solid #007bff",
              fontSize: "0.875rem",
            }}
          >
            Health Check
          </a>
          <a
            href="/api/books"
            target="_blank"
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "white",
              color: "#007bff",
              textDecoration: "none",
              borderRadius: "0.25rem",
              border: "1px solid #007bff",
              fontSize: "0.875rem",
            }}
          >
            API Books
          </a>
          <a
            href="/api/stores"
            target="_blank"
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "white",
              color: "#007bff",
              textDecoration: "none",
              borderRadius: "0.25rem",
              border: "1px solid #007bff",
              fontSize: "0.875rem",
            }}
          >
            API Stores
          </a>
          <a
            href="/api/listings"
            target="_blank"
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "white",
              color: "#007bff",
              textDecoration: "none",
              borderRadius: "0.25rem",
              border: "1px solid #007bff",
              fontSize: "0.875rem",
            }}
          >
            API Listings
          </a>
        </div>
      </div>
    </div>
  );
}
