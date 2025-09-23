export default function Home() {
  return (
    <main>
      <h1>Punto Lector API</h1>
      <p>Next.js + Prisma</p>
      <ul>
        <li>
          <a href="/health">/health</a>
        </li>
        <li>
          <a href="/api/books">/api/books</a>
        </li>
        <li>
          <a href="/api/stores">/api/stores</a>
        </li>
        <li>
          <a href="/api/listings">/api/listings</a>
        </li>
      </ul>
    </main>
  );
}
