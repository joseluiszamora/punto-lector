export default function AuthorsAdmin() {
  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "2rem",
        }}
      >
        <div>
          <h1 style={{ margin: "0 0 0.5rem 0", color: "#343a40" }}>
            Administrar Autores
          </h1>
          <p style={{ margin: 0, color: "#6c757d" }}>
            Gestionar información de autores y sus biografías
          </p>
        </div>
        <button
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#28a745",
            color: "white",
            border: "none",
            borderRadius: "0.375rem",
            cursor: "pointer",
            fontWeight: "500",
          }}
        >
          + Nuevo Autor
        </button>
      </div>

      <div
        style={{
          backgroundColor: "#f8f9fa",
          padding: "3rem 2rem",
          borderRadius: "0.5rem",
          border: "2px dashed #dee2e6",
          textAlign: "center",
          color: "#6c757d",
        }}
      >
        <div style={{ fontSize: "4rem", marginBottom: "1rem" }}>✍️</div>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Gestión de Autores
        </h3>
        <p style={{ margin: "0 0 1.5rem 0" }}>
          Administra la información completa de los autores.
        </p>
        <p style={{ margin: "0", fontSize: "0.875rem" }}>
          Incluye biografías, fechas, nacionalidad y fotos de perfil.
        </p>
      </div>

      <div style={{ marginTop: "2rem" }}>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Funciones Disponibles
        </h3>
        <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#6f42c1",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Vincular con Libros
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#fd7e14",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Gestionar Fotos
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#20c997",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Nacionalidades
          </button>
        </div>
      </div>
    </div>
  );
}
