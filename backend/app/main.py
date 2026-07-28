from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import usuarios, transacciones, precio, negocios, facturas, pagos, tickets  # Importa tickets

# 🔥 1. Crear la app ANTES de usar app.include_router
app = FastAPI(
    title="Vibra Pay API",
    description="API del ecosistema de pagos descentralizado Vibra Pay",
    version="0.1.0"
)

# 🔥 2. Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔥 3. Incluir routers (DESPUÉS de app = FastAPI())
app.include_router(usuarios.router)
app.include_router(transacciones.router)
app.include_router(precio.router)
app.include_router(negocios.router)
app.include_router(facturas.router)
app.include_router(pagos.router)
app.include_router(tickets.router)  # <-- DEBE IR AQUÍ, DESPUÉS DE app = FastAPI()

@app.get("/")
def root():
    return {
        "mensaje": "¡Bienvenido a Vibra Pay API!",
        "version": "0.1.0",
        "docs": "/docs"
    }