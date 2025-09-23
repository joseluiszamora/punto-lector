import Sidebar from "./components/Sidebar";

export const metadata = {
  title: "Punto Lector Admin",
  description: "Panel de administración para Punto Lector",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body
        style={{
          fontFamily:
            "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Arial, sans-serif",
          margin: 0,
          padding: 0,
          backgroundColor: "#f8f9fa",
        }}
      >
        <div style={{ display: "flex", minHeight: "100vh" }}>
          <Sidebar />
          <main
            style={{
              flex: 1,
              padding: "2rem",
              backgroundColor: "white",
              minHeight: "100vh",
            }}
          >
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
