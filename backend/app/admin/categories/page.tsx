export default function CategoriesAdmin() {
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
            Administrar Categorías
          </h1>
          <p style={{ margin: 0, color: "#6c757d" }}>
            Organizar y estructurar categorías jerárquicas
          </p>
        </div>
        <button
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#ffc107",
            color: "#212529",
            border: "none",
            borderRadius: "0.375rem",
            cursor: "pointer",
            fontWeight: "500",
          }}
        >
          + Nueva Categoría
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
        <div style={{ fontSize: "4rem", marginBottom: "1rem" }}>🏷️</div>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Gestión de Categorías
        </h3>
        <p style={{ margin: "0 0 1.5rem 0" }}>
          Administra categorías principales y subcategorías.
        </p>
        <p style={{ margin: "0", fontSize: "0.875rem" }}>
          Sistema jerárquico con niveles múltiples y colores personalizados.
        </p>
      </div>

      <div style={{ marginTop: "2rem" }}>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Herramientas de Categorización
        </h3>
        <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#e83e8c",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Vista Jerárquica
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#6610f2",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Ordenar Categorías
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#dc3545",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Asignar Colores
          </button>
        </div>
      </div>
    </div>
  );
}
