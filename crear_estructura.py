import os

# Lista de rutas de archivos (vacíos)
rutas = [
    "backend/requirements.txt",
    "backend/run.py",
    "backend/app/__init__.py",
    "backend/app/database.py",
    "backend/app/config.py",
    "backend/app/models.py",
    "backend/app/schemas.py",
    "backend/app/grafo.py",
    "backend/app/poiu.py",
    "backend/app/tokenomics.py",
    "backend/app/routers/__init__.py",
    "backend/app/routers/usuarios.py",
    "backend/app/routers/transacciones.py",
    "backend/app/routers/precio.py",
    "backend/app/main.py",
    "app-movil/.gitkeep",
    "docs/whitepaper.md",
    "docs/roadmap.md",
    ".gitignore",
    "README.md"
]

# Crear carpetas y archivos
for ruta in rutas:
    carpeta = os.path.dirname(ruta)
    if carpeta:
        os.makedirs(carpeta, exist_ok=True)
    with open(ruta, 'w', encoding='utf-8') as f:
        # Escribir un comentario o contenido placeholder
        if ruta.endswith(".py"):
            f.write("# Archivo creado por Vibra Pay\n")
        elif ruta.endswith(".md"):
            f.write(f"# {os.path.basename(ruta)}\n\nContenido pendiente...\n")
        elif ruta == ".gitignore":
            f.write("__pycache__/\n*.pyc\n.env\n*.db\n")
        elif ruta == "backend/requirements.txt":
            f.write("fastapi\nuvicorn\nsqlalchemy\nnetworkx\npydantic\npython-dotenv\n")
        else:
            f.write("")
    print(f"✅ Creado: {ruta}")

print("\n🎉 Estructura creada. Ahora rellena cada archivo con el contenido que te voy a dar en los mensajes siguientes.")