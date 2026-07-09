# Archivo creado por Vibra Pay
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import engine, Base
from .routers import usuarios, transacciones, precio

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Vibra Pay API",
    description="API del ecosistema de pagos descentralizado Vibra Pay",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(usuarios.router)
app.include_router(transacciones.router)
app.include_router(precio.router)

@app.get("/")
def root():
    return {
        "mensaje": "¡Bienvenido a Vibra Pay API!",
        "version": "0.1.0",
        "docs": "/docs"
    }