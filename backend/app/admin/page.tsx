export default function AdminDashboard() {
  return (
    <div>
      <h1 style={{ marginBottom: "0.5rem", color: "#343a40" }}>
        Panel de Administración
      </h1>
      <p style={{ color: "#6c757d", marginBottom: "2rem" }}>
        Gestiona todos los aspectos de Punto Lector desde aquí
      </p>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
          gap: "1.5rem",
        }}
      >
        <div
          style={{
            padding: "2rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "3rem", marginBottom: "1rem" }}>📚</div>
          <h3 style={{ margin: "0 0 0.5rem 0", color: "#495057" }}>Libros</h3>
          <p style={{ margin: "0", color: "#6c757d", fontSize: "0.9rem" }}>
            Administrar catálogo completo
          </p>
        </div>

        <div
          style={{
            padding: "2rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "3rem", marginBottom: "1rem" }}>✍️</div>
          <h3 style={{ margin: "0 0 0.5rem 0", color: "#495057" }}>Autores</h3>
          <p style={{ margin: "0", color: "#6c757d", fontSize: "0.9rem" }}>
            Gestionar información de autores
          </p>
        </div>

        <div
          style={{
            padding: "2rem",
            backgroundColor: "#f8f9fa",
            borderRadius: "0.5rem",
            border: "1px solid #dee2e6",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "3rem", marginBottom: "1rem" }}>🏷️</div>
          <h3 style={{ margin: "0 0 0.5rem 0", color: "#495057" }}>
            Categorías
          </h3>
          <p style={{ margin: "0", color: "#6c757d", fontSize: "0.9rem" }}>
            Organizar y estructurar contenido
          </p>
        </div>
      </div>
    </div>
  );
}
