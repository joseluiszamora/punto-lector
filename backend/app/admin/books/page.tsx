export default function BooksAdmin() {
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
            Administrar Libros
          </h1>
          <p style={{ margin: 0, color: "#6c757d" }}>
            Crear, editar y gestionar el catálogo de libros
          </p>
        </div>
        <button
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#007bff",
            color: "white",
            border: "none",
            borderRadius: "0.375rem",
            cursor: "pointer",
            fontWeight: "500",
          }}
        >
          + Nuevo Libro
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
        <div style={{ fontSize: "4rem", marginBottom: "1rem" }}>📚</div>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Gestión de Libros
        </h3>
        <p style={{ margin: "0 0 1.5rem 0" }}>
          Aquí podrás administrar todos los libros del catálogo.
        </p>
        <p style={{ margin: "0", fontSize: "0.875rem" }}>
          Funcionalidades: Crear, Leer, Actualizar, Eliminar libros con sus
          autores y categorías.
        </p>
      </div>

      <div style={{ marginTop: "2rem" }}>
        <h3 style={{ margin: "0 0 1rem 0", color: "#495057" }}>
          Acciones Rápidas
        </h3>
        <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#28a745",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Importar desde CSV
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#17a2b8",
              color: "white",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Exportar Catálogo
          </button>
          <button
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#ffc107",
              color: "#212529",
              border: "none",
              borderRadius: "0.25rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Estadísticas
          </button>
        </div>
      </div>
    </div>
  );
}
