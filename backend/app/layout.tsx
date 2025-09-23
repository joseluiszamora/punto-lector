export const metadata = {
  title: "Punto Lector API",
  description: "Backend API migrado a Next.js con Prisma",
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
          padding: 24,
        }}
      >
        {children}
      </body>
    </html>
  );
}
