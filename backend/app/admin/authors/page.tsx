"use client";

import { useState, useEffect, useRef } from "react";

interface Nationality {
  id: string;
  name: string;
  country_code: string;
  flag_url: string;
}

interface Author {
  id: string;
  name: string;
  bio?: string;
  birth_date?: string;
  death_date?: string;
  photo_url?: string;
  nationality_id?: string;
  nationality?: Nationality;
  _count: { books: number };
}

export default function AuthorsAdmin() {
  const [authors, setAuthors] = useState<Author[]>([]);
  const [nationalities, setNationalities] = useState<Nationality[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingAuthor, setEditingAuthor] = useState<Author | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageCropUrl, setImageCropUrl] = useState<string | null>(null);
  const [showImageCrop, setShowImageCrop] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Form state
  const [formData, setFormData] = useState({
    name: "",
    bio: "",
    birth_date: "",
    death_date: "",
    photo_url: "",
    nationality_id: "",
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [authorsResponse, nationalitiesResponse] = await Promise.all([
        fetch("/api/authors"),
        fetch("/api/nationalities"),
      ]);

      if (!authorsResponse.ok || !nationalitiesResponse.ok) {
        throw new Error("Error loading data");
      }

      const authorsData = await authorsResponse.json();
      const nationalitiesData = await nationalitiesResponse.json();

      setAuthors(authorsData);
      setNationalities(nationalitiesData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error loading data");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      const method = editingAuthor ? "PUT" : "POST";
      const body = editingAuthor
        ? { ...formData, id: editingAuthor.id }
        : formData;

      const response = await fetch("/api/authors", {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Error saving author");
      }

      await loadData();
      resetForm();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error saving author");
    }
  };

  const handleEdit = (author: Author) => {
    setEditingAuthor(author);
    setFormData({
      name: author.name,
      bio: author.bio || "",
      birth_date: author.birth_date ? author.birth_date.split("T")[0] : "",
      death_date: author.death_date ? author.death_date.split("T")[0] : "",
      photo_url: author.photo_url || "",
      nationality_id: author.nationality_id || "",
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`¿Estás seguro de eliminar el autor "${name}"?`)) return;

    try {
      const response = await fetch(`/api/authors?id=${id}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Error deleting author");
      }

      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error deleting author");
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      bio: "",
      birth_date: "",
      death_date: "",
      photo_url: "",
      nationality_id: "",
    });
    setEditingAuthor(null);
    setShowForm(false);
    setImageFile(null);
    setImageCropUrl(null);
    setShowImageCrop(false);
    setUploadingImage(false);
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && file.type.startsWith("image/")) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onload = (e) => {
        setImageCropUrl(e.target?.result as string);
        setShowImageCrop(true);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleImageCrop = async () => {
    if (!canvasRef.current || !imageCropUrl || !imageFile) return;

    setUploadingImage(true);
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      setUploadingImage(false);
      return;
    }

    const img = new Image();
    img.onload = async () => {
      // Configurar canvas cuadrado
      const size = Math.min(img.width, img.height);
      canvas.width = 300;
      canvas.height = 300;

      // Calcular posición para centrar la imagen
      const offsetX = (img.width - size) / 2;
      const offsetY = (img.height - size) / 2;

      // Dibujar imagen centrada y recortada
      ctx.drawImage(
        img,
        offsetX,
        offsetY,
        size,
        size, // Área de origen
        0,
        0,
        300,
        300 // Área destino
      );

      // Convertir canvas a blob
      canvas.toBlob(
        async (blob) => {
          if (blob) {
            try {
              // Crear FormData para subir imagen
              const formData = new FormData();
              formData.append("file", blob, `author-${Date.now()}.jpg`);
              formData.append("bucket", "author_photos");

              // Subir imagen a Supabase
              const response = await fetch("/api/upload", {
                method: "POST",
                body: formData,
              });

              if (!response.ok) {
                throw new Error("Error uploading image");
              }

              const data = await response.json();

              // Actualizar URL en el formulario con la URL de Supabase
              setFormData((prev) => ({ ...prev, photo_url: data.url }));
              setShowImageCrop(false);
              setError(null);
            } catch (err) {
              setError(
                "Error subiendo imagen: " +
                  (err instanceof Error ? err.message : "Error desconocido")
              );
            }
          }
          setUploadingImage(false);
        },
        "image/jpeg",
        0.9
      );
    };
    img.src = imageCropUrl;
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return "";
    return new Date(dateString).toLocaleDateString("es-ES", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  const calculateAge = (birthDate?: string, deathDate?: string) => {
    if (!birthDate) return "";
    const birth = new Date(birthDate);
    const end = deathDate ? new Date(deathDate) : new Date();
    const age = end.getFullYear() - birth.getFullYear();
    return `${age} años${deathDate ? " (al fallecer)" : ""}`;
  };

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
          onClick={() => setShowForm(true)}
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
              maxWidth: "600px",
              maxHeight: "90vh",
              overflow: "auto",
            }}
          >
            <h2 style={{ margin: "0 0 1.5rem 0" }}>
              {editingAuthor ? "Editar Autor" : "Nuevo Autor"}
            </h2>

            <form onSubmit={handleSubmit}>
              <div
                style={{ display: "flex", gap: "1rem", marginBottom: "1rem" }}
              >
                {/* Foto */}
                <div style={{ flex: "0 0 120px" }}>
                  <label
                    style={{
                      display: "block",
                      marginBottom: "0.5rem",
                      fontWeight: "500",
                    }}
                  >
                    Foto
                  </label>
                  <div
                    onClick={() => fileInputRef.current?.click()}
                    style={{
                      width: "120px",
                      height: "120px",
                      border: "2px dashed #ced4da",
                      borderRadius: "0.375rem",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      cursor: "pointer",
                      backgroundImage: formData.photo_url
                        ? `url(${formData.photo_url})`
                        : "none",
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                      color: formData.photo_url ? "transparent" : "#6c757d",
                    }}
                  >
                    {!formData.photo_url && "📷"}
                  </div>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleImageSelect}
                    style={{ display: "none" }}
                  />
                  {formData.photo_url && (
                    <button
                      type="button"
                      onClick={() =>
                        setFormData((prev) => ({ ...prev, photo_url: "" }))
                      }
                      style={{
                        marginTop: "0.5rem",
                        padding: "0.25rem 0.5rem",
                        backgroundColor: "#dc3545",
                        color: "white",
                        border: "none",
                        borderRadius: "0.25rem",
                        cursor: "pointer",
                        fontSize: "0.75rem",
                        width: "100%",
                      }}
                    >
                      Quitar
                    </button>
                  )}
                </div>

                {/* Información básica */}
                <div style={{ flex: 1 }}>
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
                      Nacionalidad
                    </label>
                    <select
                      value={formData.nationality_id}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          nationality_id: e.target.value,
                        })
                      }
                      style={{
                        width: "100%",
                        padding: "0.75rem",
                        border: "1px solid #ced4da",
                        borderRadius: "0.375rem",
                        fontSize: "1rem",
                      }}
                    >
                      <option value="">-- Seleccionar nacionalidad --</option>
                      {nationalities.map((nationality) => (
                        <option key={nationality.id} value={nationality.id}>
                          {nationality.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* Fechas */}
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
                    Fecha de Nacimiento
                  </label>
                  <input
                    type="date"
                    value={formData.birth_date}
                    onChange={(e) =>
                      setFormData({ ...formData, birth_date: e.target.value })
                    }
                    style={{
                      width: "100%",
                      padding: "0.75rem",
                      border: "1px solid #ced4da",
                      borderRadius: "0.375rem",
                      fontSize: "1rem",
                    }}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label
                    style={{
                      display: "block",
                      marginBottom: "0.5rem",
                      fontWeight: "500",
                    }}
                  >
                    Fecha de Fallecimiento
                  </label>
                  <input
                    type="date"
                    value={formData.death_date}
                    onChange={(e) =>
                      setFormData({ ...formData, death_date: e.target.value })
                    }
                    style={{
                      width: "100%",
                      padding: "0.75rem",
                      border: "1px solid #ced4da",
                      borderRadius: "0.375rem",
                      fontSize: "1rem",
                    }}
                  />
                </div>
              </div>

              {/* Biografía */}
              <div style={{ marginBottom: "1rem" }}>
                <label
                  style={{
                    display: "block",
                    marginBottom: "0.5rem",
                    fontWeight: "500",
                  }}
                >
                  Biografía
                </label>
                <textarea
                  value={formData.bio}
                  onChange={(e) =>
                    setFormData({ ...formData, bio: e.target.value })
                  }
                  rows={5}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ced4da",
                    borderRadius: "0.375rem",
                    fontSize: "1rem",
                    resize: "vertical",
                  }}
                  placeholder="Escribe la biografía del autor..."
                />
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
                  {editingAuthor ? "Actualizar" : "Crear"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal de crop de imagen */}
      {showImageCrop && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: "rgba(0,0,0,0.8)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1100,
          }}
        >
          <div
            style={{
              backgroundColor: "white",
              padding: "2rem",
              borderRadius: "0.5rem",
              textAlign: "center",
              maxWidth: "500px",
              width: "90%",
            }}
          >
            <h3 style={{ margin: "0 0 1rem 0" }}>Ajustar Imagen</h3>
            <p
              style={{
                margin: "0 0 1rem 0",
                color: "#6c757d",
                fontSize: "0.875rem",
              }}
            >
              La imagen se recortará automáticamente al centro en formato
              cuadrado
            </p>
            <div style={{ marginBottom: "1.5rem" }}>
              <img
                src={imageCropUrl!}
                alt="Preview"
                style={{
                  maxWidth: "100%",
                  maxHeight: "300px",
                  border: "2px solid #007bff",
                  borderRadius: "0.375rem",
                  objectFit: "contain",
                }}
              />
            </div>
            <canvas ref={canvasRef} style={{ display: "none" }} />

            {uploadingImage && (
              <div style={{ marginBottom: "1rem", color: "#007bff" }}>
                <div style={{ fontSize: "1.5rem", marginBottom: "0.5rem" }}>
                  ⏳
                </div>
                Subiendo imagen a Supabase...
              </div>
            )}

            <div
              style={{ display: "flex", gap: "1rem", justifyContent: "center" }}
            >
              <button
                onClick={() => setShowImageCrop(false)}
                disabled={uploadingImage}
                style={{
                  padding: "0.75rem 1.5rem",
                  backgroundColor: uploadingImage ? "#6c757d" : "#6c757d",
                  color: "white",
                  border: "none",
                  borderRadius: "0.375rem",
                  cursor: uploadingImage ? "not-allowed" : "pointer",
                  opacity: uploadingImage ? 0.7 : 1,
                }}
              >
                Cancelar
              </button>
              <button
                onClick={handleImageCrop}
                disabled={uploadingImage}
                style={{
                  padding: "0.75rem 1.5rem",
                  backgroundColor: uploadingImage ? "#6c757d" : "#28a745",
                  color: "white",
                  border: "none",
                  borderRadius: "0.375rem",
                  cursor: uploadingImage ? "not-allowed" : "pointer",
                  opacity: uploadingImage ? 0.7 : 1,
                  fontWeight: "500",
                }}
              >
                {uploadingImage ? "Subiendo..." : "Usar Imagen"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Lista de autores */}
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
            Cargando autores...
          </div>
        ) : authors.length === 0 ? (
          <div
            style={{ padding: "3rem", textAlign: "center", color: "#6c757d" }}
          >
            <div style={{ fontSize: "3rem", marginBottom: "1rem" }}>👨‍💻</div>
            <p>No hay autores registrados</p>
            <button
              onClick={() => setShowForm(true)}
              style={{
                padding: "0.75rem 1.5rem",
                backgroundColor: "#28a745",
                color: "white",
                border: "none",
                borderRadius: "0.375rem",
                cursor: "pointer",
                marginTop: "1rem",
              }}
            >
              Crear primer autor
            </button>
          </div>
        ) : (
          <div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "80px 1fr 200px 150px 100px 150px",
                padding: "1rem",
                backgroundColor: "#f8f9fa",
                borderBottom: "1px solid #dee2e6",
                fontWeight: "600",
                fontSize: "0.875rem",
              }}
            >
              <div>Foto</div>
              <div>Autor</div>
              <div>Nacionalidad</div>
              <div>Nacimiento</div>
              <div>Libros</div>
              <div>Acciones</div>
            </div>
            {authors.map((author) => (
              <div
                key={author.id}
                style={{
                  display: "grid",
                  gridTemplateColumns: "80px 1fr 200px 150px 100px 150px",
                  padding: "1rem",
                  borderBottom: "1px solid #dee2e6",
                  alignItems: "center",
                }}
              >
                <div>
                  {author.photo_url ? (
                    <img
                      src={author.photo_url}
                      alt={author.name}
                      style={{
                        width: "60px",
                        height: "60px",
                        borderRadius: "50%",
                        objectFit: "cover",
                        border: "2px solid #dee2e6",
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: "60px",
                        height: "60px",
                        borderRadius: "50%",
                        backgroundColor: "#e9ecef",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: "1.5rem",
                      }}
                    >
                      👤
                    </div>
                  )}
                </div>
                <div>
                  <div style={{ fontWeight: "500", marginBottom: "0.25rem" }}>
                    {author.name}
                  </div>
                  {author.bio && (
                    <div
                      style={{
                        fontSize: "0.875rem",
                        color: "#6c757d",
                        lineHeight: "1.3",
                      }}
                    >
                      {author.bio.substring(0, 120)}
                      {author.bio.length > 120 && "..."}
                    </div>
                  )}
                  {(author.birth_date || author.death_date) && (
                    <div
                      style={{
                        fontSize: "0.75rem",
                        color: "#6c757d",
                        marginTop: "0.25rem",
                      }}
                    >
                      {calculateAge(author.birth_date, author.death_date)}
                    </div>
                  )}
                </div>
                <div>
                  {author.nationality ? (
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "0.5rem",
                      }}
                    >
                      <img
                        src={author.nationality.flag_url}
                        alt={author.nationality.country_code}
                        style={{ width: "20px", height: "15px" }}
                      />
                      <span style={{ fontSize: "0.875rem" }}>
                        {author.nationality.name}
                      </span>
                    </div>
                  ) : (
                    <span style={{ color: "#6c757d", fontSize: "0.875rem" }}>
                      No especificada
                    </span>
                  )}
                </div>
                <div style={{ color: "#6c757d", fontSize: "0.875rem" }}>
                  {formatDate(author.birth_date)}
                </div>
                <div style={{ color: "#6c757d" }}>{author._count.books}</div>
                <div style={{ display: "flex", gap: "0.5rem" }}>
                  <button
                    onClick={() => handleEdit(author)}
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
                    onClick={() => handleDelete(author.id, author.name)}
                    disabled={author._count.books > 0}
                    style={{
                      padding: "0.25rem 0.5rem",
                      backgroundColor:
                        author._count.books > 0 ? "#6c757d" : "#dc3545",
                      color: "white",
                      border: "none",
                      borderRadius: "0.25rem",
                      cursor:
                        author._count.books > 0 ? "not-allowed" : "pointer",
                      fontSize: "0.75rem",
                    }}
                    title={
                      author._count.books > 0
                        ? "No se puede eliminar: tiene libros asociados"
                        : "Eliminar autor"
                    }
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div
        style={{ marginTop: "1.5rem", fontSize: "0.875rem", color: "#6c757d" }}
      >
        <p>
          <strong>Nota:</strong> Los autores con libros asociados no pueden ser
          eliminados.
        </p>
      </div>
    </div>
  );
}
