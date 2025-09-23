# Punto Lector Backend

Backend API para la aplicación Punto Lector migrado a Next.js (App Router) con Prisma.

## Características

- ✅ Next.js 14 (App Router) en modo Node.js runtime para APIs
- ✅ Prisma ORM para PostgreSQL (Supabase)
- ✅ Rutas API en `app/api/*`
- ✅ Healthcheck en `app/health`
- ✅ CORS básico en handlers
- ✅ Variables de entorno con `.env.local`

## Configuración

### 1. Instalar dependencias

```bash
cd backend
npm install
```

### 2. Configurar variables de entorno

```bash
cp .env.local.example .env.local
```

Edita `.env.local` con tus credenciales de base de datos (Supabase):

```env
DATABASE_URL="postgresql://postgres:tu-password@db.tu-proyecto.supabase.co:5432/postgres"
DIRECT_URL="postgresql://postgres:tu-password@db.tu-proyecto.supabase.co:5432/postgres"
CORS_ORIGIN=*
```

### 3. Generar cliente Prisma

```bash
npm run db:generate
```

### 4. (Opcional) Ejecutar seed de datos de prueba

```bash
npm run db:seed
```

## Scripts disponibles

```bash
# Desarrollo (puerto 3001)
npm run dev

# Build de producción
npm run build

# Start producción
npm start

# Prisma
npm run db:generate
npm run db:migrate
npm run db:studio
npm run db:seed
```

## Endpoints API

### Salud

- `GET /health` - Verificar estado del servidor y base de datos

### Libros

- `GET /api/books` - Listar libros
  - Query params: `search`, `author`, `limit`

### Tiendas

- `GET /api/stores` - Listar tiendas
  - Query params: `active`

### Listados

- `GET /api/listings` - Listar libros en venta
  - Query params: `store_id`, `book_id`, `active`

## Estructura del proyecto

```
backend/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── health/
│   │   └── route.ts
│   └── api/
│       ├── books/route.ts
│       ├── stores/route.ts
│       └── listings/route.ts
├── lib/
│   ├── prisma.ts
│   └── cors.ts
├── prisma/
│   └── schema.prisma
├── scripts/
│   └── seed.ts
├── next.config.js
├── package.json
├── tsconfig.json
└── .env.local
```

## Desarrollo

Servidor Next.js por defecto en http://localhost:3001

Para verificar:

1. `npm run dev`
2. Visita http://localhost:3001/health
3. Deberías ver `{"status":"healthy","database":"connected"}`
