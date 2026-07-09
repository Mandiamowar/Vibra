# Archivo creado por Vibra Pay
import networkx as nx
import hashlib
import json
from datetime import datetime
from sqlalchemy.orm import Session

from .models import NodoGrafo, Transaccion

class GrafoTemporal:
    def __init__(self, db: Session):
        self.db = db
        self.grafo = nx.DiGraph()
        self._cargar_nodos()
    
    def _cargar_nodos(self):
        nodos = self.db.query(NodoGrafo).all()
        for nodo in nodos:
            self.grafo.add_node(nodo.hash_nodo, transaccion_id=nodo.transaccion_id, timestamp=nodo.timestamp)
            if nodo.enlaces_previos:
                previos = json.loads(nodo.enlaces_previos)
                for prev in previos:
                    self.grafo.add_edge(prev, nodo.hash_nodo)
    
    def crear_nodo(self, transaccion_id: int, previos_ids: list = None) -> str:
        tx = self.db.query(Transaccion).filter(Transaccion.id == transaccion_id).first()
        if not tx:
            raise ValueError(f"Transacción {transaccion_id} no encontrada")
        data = {
            "tx_id": transaccion_id,
            "emisor": tx.emisor_id,
            "receptor": tx.receptor_id,
            "monto": tx.monto,
            "timestamp": datetime.utcnow().isoformat(),
            "previos": previos_ids or []
        }
        hash_nodo = hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()
        nodo_bd = NodoGrafo(
            transaccion_id=transaccion_id,
            hash_nodo=hash_nodo,
            enlaces_previos=json.dumps(previos_ids or [])
        )
        self.db.add(nodo_bd)
        self.db.commit()
        self.grafo.add_node(hash_nodo, transaccion_id=transaccion_id, timestamp=datetime.utcnow())
        if previos_ids:
            for prev_id in previos_ids:
                self.grafo.add_edge(prev_id, hash_nodo)
        return hash_nodo
    
    def verificar_integridad(self, hash_nodo: str) -> bool:
        if hash_nodo not in self.grafo:
            return False
        try:
            ciclos = list(nx.simple_cycles(self.grafo))
            return len(ciclos) == 0
        except:
            return False
    
    def obtener_historial(self, hash_nodo: str) -> list:
        if hash_nodo not in self.grafo:
            return []
        try:
            predecesores = list(nx.ancestors(self.grafo, hash_nodo))
            return sorted(predecesores, key=lambda x: self.grafo.nodes[x]['timestamp'])
        except:
            return []