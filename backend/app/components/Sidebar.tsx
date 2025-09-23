"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { href: "/admin", label: "Dashboard", icon: "📊" },
  { href: "/admin/books", label: "Libros", icon: "📚" },
  { href: "/admin/authors", label: "Autores", icon: "✍️" },
  { href: "/admin/categories", label: "Categorías", icon: "🏷️" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside
      style={{
        width: "250px",
        minHeight: "100vh",
        backgroundColor: "#f8f9fa",
        borderRight: "1px solid #dee2e6",
        padding: "0",
      }}
    >
      <div
        style={{
          padding: "1.5rem",
          borderBottom: "1px solid #dee2e6",
          backgroundColor: "#343a40",
          color: "white",
        }}
      >
        <h2 style={{ margin: 0, fontSize: "1.25rem", fontWeight: "600" }}>
          Punto Lector Admin
        </h2>
      </div>

      <nav style={{ padding: "1rem 0" }}>
        <ul
          style={{
            listStyle: "none",
            padding: 0,
            margin: 0,
          }}
        >
          {navItems.map((item) => {
            const isActive = pathname === item.href;

            return (
              <li key={item.href} style={{ margin: 0 }}>
                <Link
                  href={item.href}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    padding: "0.75rem 1.5rem",
                    textDecoration: "none",
                    color: isActive ? "#0066cc" : "#495057",
                    backgroundColor: isActive ? "#e7f3ff" : "transparent",
                    borderLeft: isActive
                      ? "3px solid #0066cc"
                      : "3px solid transparent",
                    transition: "all 0.2s ease",
                  }}
                >
                  <span
                    style={{
                      marginRight: "0.75rem",
                      fontSize: "1.1rem",
                    }}
                  >
                    {item.icon}
                  </span>
                  <span style={{ fontWeight: isActive ? "600" : "400" }}>
                    {item.label}
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div
        style={{
          position: "absolute",
          bottom: "1rem",
          left: "1rem",
          right: "1rem",
          padding: "1rem",
          backgroundColor: "#e9ecef",
          borderRadius: "0.375rem",
          fontSize: "0.875rem",
          color: "#6c757d",
        }}
      >
        <div>
          API Status: <span style={{ color: "#28a745" }}>● Online</span>
        </div>
        <div style={{ marginTop: "0.5rem" }}>
          <Link
            href="/health"
            style={{ color: "#0066cc", textDecoration: "none" }}
          >
            Ver health check
          </Link>
        </div>
      </div>
    </aside>
  );
}
