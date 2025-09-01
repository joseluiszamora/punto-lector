# Punto Lector Backend

Backend API para la aplicación Punto Lector desarrollado con Node.js, TypeScript, Express y Prisma.

## Características

- ✅ Express.js con TypeScript
- ✅ Prisma ORM para base de datos
- ✅ Conexión a Supabase PostgreSQL
- ✅ CORS habilitado
- ✅ Variables de entorno
- ✅ Scripts de desarrollo y producción

## Configuración

### 1. Instalar dependencias

```bash
cd backend
npm install
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita el archivo `.env` con tus credenciales de Supabase:

```env
DATABASE_URL="postgresql://postgres:tu-password@db.tu-proyecto.supabase.co:5432/postgres"
PORT=3001
NODE_ENV=development
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
# Desarrollo con hot reload
npm run dev

# Compilar a JavaScript
npm run build

# Producción
npm start

# Generar cliente Prisma
npm run db:generate

# Abrir Prisma Studio
npm run db:studio

# Ejecutar seed
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
├── src/
│   ├── index.ts        # Servidor principal
│   └── seed.ts         # Datos de prueba
├── prisma/
│   └── schema.prisma   # Esquema de base de datos
├── package.json
├── tsconfig.json
└── .env
```

## Desarrollo

El servidor se ejecuta por defecto en http://localhost:3001

Para verificar que todo funciona:

1. `npm run dev`
2. Visita http://localhost:3001/health
3. Deberías ver `{"status":"healthy","database":"connected"}`
