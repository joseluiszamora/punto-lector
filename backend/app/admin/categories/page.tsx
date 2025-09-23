"use client";

import { useState, useEffect } from "react";

interface Category {
  id: string;
  name: string;
  description?: string;
  color?: string;
  level: number;
  sort_order: number;
  parent_id?: string;
  parent?: { id: string; name: string };
  children?: { id: string; name: string }[];
  _count: { books: number; children: number };
}

export default function CategoriesAdmin() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(
    new Set()
  );

  // Form state
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    color: "#E74C3C",
    parent_id: "",
    sort_order: 0,
  });

  useEffect(() => {
    loadCategories();
  }, []);

  const loadCategories = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/categories");
      if (!response.ok) throw new Error("Error loading categories");
      const data = await response.json();
      setCategories(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error loading categories");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      const method = editingCategory ? "PUT" : "POST";
      const body = editingCategory
        ? { ...formData, id: editingCategory.id }
        : formData;

      const response = await fetch("/api/categories", {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Error saving category");
      }

      await loadCategories();
      resetForm();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error saving category");
    }
  };

  const handleEdit = (category: Category) => {
    setEditingCategory(category);
    setFormData({
      name: category.name,
      description: category.description || "",
      color: category.color || "#E74C3C",
      parent_id: category.parent_id || "",
      sort_order: category.sort_order,
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`¿Estás seguro de eliminar la categoría "${name}"?`)) return;

    try {
      const response = await fetch(`/api/categories?id=${id}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Error deleting category");
      }

      await loadCategories();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error deleting category");
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      color: "#E74C3C",
      parent_id: "",
      sort_order: 0,
    });
    setEditingCategory(null);
    setShowForm(false);
  };

  const toggleExpand = (categoryId: string) => {
    const newExpanded = new Set(expandedCategories);
    if (newExpanded.has(categoryId)) {
      newExpanded.delete(categoryId);
    } else {
      newExpanded.add(categoryId);
    }
    setExpandedCategories(newExpanded);
  };

  const getChildCategories = (parentId: string): Category[] => {
    return categories
      .filter((cat) => cat.parent_id === parentId)
      .sort((a, b) => a.sort_order - b.sort_order);
  };

  const renderCategoryRow = (category: Category, depth: number = 0) => {
    const hasChildren = category._count.children > 0;
    const isExpanded = expandedCategories.has(category.id);
    const children = getChildCategories(category.id);

    return (
      <div key={category.id}>
        {/* Fila principal */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 100px 80px 80px 150px",
            padding: "1rem",
            borderBottom: "1px solid #dee2e6",
            alignItems: "center",
            backgroundColor: depth > 0 ? "#f8f9fa" : "white",
          }}
        >
          <div style={{ paddingLeft: `${depth * 1.5}rem` }}>
            <div
              style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}
            >
              {/* Botón de expandir/colapsar */}
              {hasChildren ? (
                <button
                  onClick={() => toggleExpand(category.id)}
                  style={{
                    background: "none",
                    border: "none",
                    cursor: "pointer",
                    padding: "0.25rem",
                    display: "flex",
                    alignItems: "center",
                    color: "#6c757d",
                    fontSize: "0.75rem",
                    minWidth: "20px",
                    justifyContent: "center",
                  }}
                >
                  {isExpanded ? "▼" : "▶"}
                </button>
              ) : (
                <div style={{ width: "20px" }} />
              )}

              {/* Color indicator */}
              {category.color && (
                <div
                  style={{
                    width: "20px",
                    height: "20px",
                    backgroundColor: category.color,
                    borderRadius: "3px",
                    border: "1px solid #dee2e6",
                    flexShrink: 0,
                  }}
                />
              )}

              {/* Category info */}
              <div>
                <div
                  style={{
                    fontWeight: "500",
                    display: "flex",
                    alignItems: "center",
                    gap: "0.5rem",
                  }}
                >
                  {category.name}
                  {hasChildren && (
                    <span
                      style={{
                        fontSize: "0.75rem",
                        color: "#6c757d",
                        background: "#e9ecef",
                        padding: "0.125rem 0.375rem",
                        borderRadius: "0.25rem",
                      }}
                    >
                      {category._count.children}
                    </span>
                  )}
                </div>
                {category.description && (
                  <div
                    style={{
                      fontSize: "0.875rem",
                      color: "#6c757d",
                      marginTop: "0.25rem",
                    }}
                  >
                    {category.description}
                  </div>
                )}
              </div>
            </div>
          </div>
          <div style={{ color: "#6c757d" }}>Nivel {category.level}</div>
          <div style={{ color: "#6c757d" }}>{category.sort_order}</div>
          <div style={{ color: "#6c757d" }}>{category._count.books}</div>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            <button
              onClick={() => handleEdit(category)}
              style={{
                padding: "0.25rem 0.5rem",
                backgroundColor: "#007bff",
                color: "white",
                border: "none",
                borderRadius: "0.25rem",
                cursor: "pointer",
                fontSize: "0.75rem",
              }}
            >
              Editar
            </button>
            <button
              onClick={() => handleDelete(category.id, category.name)}
              disabled={
                category._count.children > 0 || category._count.books > 0
              }
              style={{
                padding: "0.25rem 0.5rem",
                backgroundColor:
                  category._count.children > 0 || category._count.books > 0
                    ? "#6c757d"
                    : "#dc3545",
                color: "white",
                border: "none",
                borderRadius: "0.25rem",
                cursor:
                  category._count.children > 0 || category._count.books > 0
                    ? "not-allowed"
                    : "pointer",
                fontSize: "0.75rem",
              }}
              title={
                category._count.children > 0
                  ? "No se puede eliminar: tiene subcategorías"
                  : category._count.books > 0
                  ? "No se puede eliminar: tiene libros asociados"
                  : "Eliminar categoría"
              }
            >
              Eliminar
            </button>
          </div>
        </div>

        {/* Renderizar hijos si está expandido */}
        {isExpanded &&
          children.map((child) => renderCategoryRow(child, depth + 1))}
      </div>
    );
  };

  const rootCategories = categories
    .filter((cat) => cat.level === 0)
    .sort((a, b) => a.sort_order - b.sort_order);

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
        <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
          <button
            onClick={() =>
              setExpandedCategories(new Set(categories.map((c) => c.id)))
            }
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#17a2b8",
              color: "white",
              border: "none",
              borderRadius: "0.375rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Expandir Todo
          </button>
          <button
            onClick={() => setExpandedCategories(new Set())}
            style={{
              padding: "0.5rem 1rem",
              backgroundColor: "#6c757d",
              color: "white",
              border: "none",
              borderRadius: "0.375rem",
              cursor: "pointer",
              fontSize: "0.875rem",
            }}
          >
            Colapsar Todo
          </button>
          <button
            onClick={() => setShowForm(true)}
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
      </div>

      {error && (
        <div
          style={{
            padding: "1rem",
            backgroundColor: "#f8d7da",
            color: "#721c24",
            borderRadius: "0.375rem",
            marginBottom: "1rem",
            border: "1px solid #f5c6cb",
          }}
        >
          {error}
        </div>
      )}

      {/* Formulario */}
      {showForm && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: "rgba(0,0,0,0.5)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1000,
          }}
        >
          <div
            style={{
              backgroundColor: "white",
              padding: "2rem",
              borderRadius: "0.5rem",
              width: "90%",
              maxWidth: "500px",
              maxHeight: "90vh",
              overflow: "auto",
            }}
          >
            <h2 style={{ margin: "0 0 1.5rem 0" }}>
              {editingCategory ? "Editar Categoría" : "Nueva Categoría"}
            </h2>

            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: "1rem" }}>
                <label
                  style={{
                    display: "block",
                    marginBottom: "0.5rem",
                    fontWeight: "500",
                  }}
                >
                  Nombre *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ced4da",
                    borderRadius: "0.375rem",
                    fontSize: "1rem",
                  }}
                  required
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label
                  style={{
                    display: "block",
                    marginBottom: "0.5rem",
                    fontWeight: "500",
                  }}
                >
                  Descripción
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  rows={3}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ced4da",
                    borderRadius: "0.375rem",
                    fontSize: "1rem",
                    resize: "vertical",
                  }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label
                  style={{
                    display: "block",
                    marginBottom: "0.5rem",
                    fontWeight: "500",
                  }}
                >
                  Categoría Padre
                </label>
                <select
                  value={formData.parent_id}
                  onChange={(e) =>
                    setFormData({ ...formData, parent_id: e.target.value })
                  }
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ced4da",
                    borderRadius: "0.375rem",
                    fontSize: "1rem",
                  }}
                >
                  <option value="">-- Sin categoría padre --</option>
                  {categories
                    .filter((cat) =>
                      editingCategory ? cat.id !== editingCategory.id : true
                    )
                    .map((category) => (
                      <option key={category.id} value={category.id}>
                        {"  ".repeat(category.level)} {category.name}
                      </option>
                    ))}
                </select>
              </div>

              <div
                style={{ display: "flex", gap: "1rem", marginBottom: "1rem" }}
              >
                <div style={{ flex: 1 }}>
                  <label
                    style={{
                      display: "block",
                      marginBottom: "0.5rem",
                      fontWeight: "500",
                    }}
                  >
                    Color
                  </label>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.5rem",
                    }}
                  >
                    <input
                      type="color"
                      value={formData.color}
                      onChange={(e) =>
                        setFormData({ ...formData, color: e.target.value })
                      }
                      style={{
                        width: "50px",
                        height: "40px",
                        border: "1px solid #ced4da",
                        borderRadius: "0.375rem",
                        cursor: "pointer",
                      }}
                    />
                    <input
                      type="text"
                      value={formData.color}
                      onChange={(e) =>
                        setFormData({ ...formData, color: e.target.value })
                      }
                      style={{
                        flex: 1,
                        padding: "0.5rem",
                        border: "1px solid #ced4da",
                        borderRadius: "0.375rem",
                        fontSize: "0.9rem",
                      }}
                      pattern="^#[0-9A-Fa-f]{6}$"
                      placeholder="#E74C3C"
                    />
                  </div>
                </div>

                <div style={{ flex: 1 }}>
                  <label
                    style={{
                      display: "block",
                      marginBottom: "0.5rem",
                      fontWeight: "500",
                    }}
                  >
                    Orden
                  </label>
                  <input
                    type="number"
                    value={formData.sort_order}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        sort_order: parseInt(e.target.value) || 0,
                      })
                    }
                    style={{
                      width: "100%",
                      padding: "0.75rem",
                      border: "1px solid #ced4da",
                      borderRadius: "0.375rem",
                      fontSize: "1rem",
                    }}
                    min="0"
                  />
                </div>
              </div>

              <div
                style={{
                  display: "flex",
                  gap: "1rem",
                  justifyContent: "flex-end",
                }}
              >
                <button
                  type="button"
                  onClick={resetForm}
                  style={{
                    padding: "0.75rem 1.5rem",
                    backgroundColor: "#6c757d",
                    color: "white",
                    border: "none",
                    borderRadius: "0.375rem",
                    cursor: "pointer",
                  }}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
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
                  {editingCategory ? "Actualizar" : "Crear"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Lista de categorías en estructura de árbol */}
      <div
        style={{
          backgroundColor: "white",
          borderRadius: "0.5rem",
          border: "1px solid #dee2e6",
          overflow: "hidden",
        }}
      >
        {loading ? (
          <div
            style={{ padding: "2rem", textAlign: "center", color: "#6c757d" }}
          >
            Cargando categorías...
          </div>
        ) : categories.length === 0 ? (
          <div
            style={{ padding: "3rem", textAlign: "center", color: "#6c757d" }}
          >
            <div style={{ fontSize: "3rem", marginBottom: "1rem" }}>🏷️</div>
            <p>No hay categorías creadas</p>
            <button
              onClick={() => setShowForm(true)}
              style={{
                padding: "0.75rem 1.5rem",
                backgroundColor: "#ffc107",
                color: "#212529",
                border: "none",
                borderRadius: "0.375rem",
                cursor: "pointer",
                marginTop: "1rem",
              }}
            >
              Crear primera categoría
            </button>
          </div>
        ) : (
          <div>
            {/* Encabezados */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 100px 80px 80px 150px",
                padding: "1rem",
                backgroundColor: "#f8f9fa",
                borderBottom: "1px solid #dee2e6",
                fontWeight: "600",
                fontSize: "0.875rem",
              }}
            >
              <div>Categoría</div>
              <div>Nivel</div>
              <div>Orden</div>
              <div>Libros</div>
              <div>Acciones</div>
            </div>

            {/* Renderizar solo categorías padre, los hijos se renderizan recursivamente */}
            {rootCategories.map((category) => renderCategoryRow(category, 0))}
          </div>
        )}
      </div>

      <div
        style={{ marginTop: "1.5rem", fontSize: "0.875rem", color: "#6c757d" }}
      >
        <div style={{ display: "flex", gap: "2rem", flexWrap: "wrap" }}>
          <p>
            <strong>💡 Consejos:</strong>
          </p>
          <p>• Haz clic en ▶ para expandir subcategorías</p>
          <p>
            • Las categorías con subcategorías o libros no pueden eliminarse
          </p>
          <p>• Usa "Expandir/Colapsar Todo" para navegar rápidamente</p>
        </div>
      </div>
    </div>
  );
}
