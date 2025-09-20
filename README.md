# 🎟️ Sistema de Venta de Tickets - POC con Load Balancing

## Integrantes
-  Adrian Antonio Auqui Perez
- Jose Barrenchea Merino

## 📌 Descripción del Proyecto
Proof of Concept (POC) de un sistema distribuido de venta de tickets que implementa **load balancing**, **caching** y **microservicios**, con el objetivo de demostrar la elección de tecnologías adecuadas bajo un **presupuesto limitado**.

---

## 🧠 Decisión Arquitectónica Fundamental
- **Prioridad:** Consistencia sobre velocidad  
- **Justificación:**  
  - No podemos vender el mismo asiento dos veces.  
  - Los errores de *double-booking* causan pérdidas económicas y mala experiencia de usuario.  
  - La velocidad es importante, pero **secundaria frente a la integridad de transacciones**.  

---

## 🛠️ Stack Tecnológico Seleccionado

### 1. Load Balancer
- **Tecnología:** Gateway en Node.js (Express.js) con algoritmo Round Robin.  
- **Métricas:**  
  - Costo: $0  
  - Consumo: ~10MB RAM  
  - Overhead: < 10ms por request  
  - Complejidad: baja (100 líneas de código)  
- **Alternativas descartadas:**  
  - Nginx: configuración extra e instalación separada  
  - HAProxy: overkill para este caso  
  - Kong: más recursos, más complejidad  
  - AWS ELB: $16+/mes fuera de presupuesto  
- **Justificación Algoritmo:**  
  - Servidores con capacidad similar (3 cores, 128GB).  
  - Tests muestran distribución **50-50 perfecta**.  

---

### 2. Cache
- **Tecnología:** Cache in-memory (Objeto JavaScript) con TTL de 30s.  
- **Métricas:**  
  - Costo: $0  
  - Hit Rate: 80% en requests consecutivas  
  - Overhead: incluido en el proceso Node.js  
- **Alternativas descartadas:**  
  - Redis: $20-50/mes y mantenimiento adicional  
  - Memcached: instalación separada innecesaria  
  - Redis Cluster: over-engineering  
- **Trade-off:** cache no compartida entre instancias (aceptable en POC).  

---

### 3. Microservicios
- **Tecnología:** Express.js (Node.js).  
- **Métricas:**  
  - Tiempo de desarrollo: 2-3 horas  
  - Performance: < 5ms respuesta promedio  
  - Footprint: ~50MB RAM por instancia  
- **Justificación:**  
  - Framework conocido por el equipo  
  - Ecosistema maduro  
  - Sin costo de licencias  

---

## 🏗️ Arquitectura Implementada
```text
Usuario
   ↓
Gateway (Puerto 8080)
   ↓
Load Balancer (Round Robin)
   ├── Sales Service 1 (Puerto 3001)
   ├── Sales Service 2 (Puerto 3011)
   ├── Accounting Service 1 (Puerto 3002)
   └── Accounting Service 2 (Puerto 3012)
```

---

## 📊 Resultados de Testing

### Test 1: Load Balancing
- Configuración: 100 requests concurrentes  
- Distribución:  
  - sales-3001 → 50%  
  - sales-3011 → 50%  
- Performance:  
  - Avg: 4.51ms  
  - Min: 2ms  
  - Max: 83.64ms  
- **Estado:** ✓ Balanceo perfecto (desviación < 15%).  

### Test 2: Performance
| Métrica              | Valor      | Objetivo    | Estado     |
|----------------------|-----------|-------------|------------|
| Tiempo promedio      | 4.51ms    | < 100ms     | ✓ Excelente |
| P95                  | < 50ms    | < 500ms     | ✓ Excelente |
| Throughput           | 100+ req/s| 50 req/s    | ✓ Supera    |

### Test 3: Funcionalidad
- **Total Tests:** 6  
- **Passed:** 6/6  
- ✓ Health checks funcionando  
- ✓ CRUD de tickets operativo  
- ✓ Procesamiento de órdenes correcto  
- ✓ Reportes financieros generados  

### Test 4: Concurrencia
- **Problema:** Race condition bajo carga extrema (50+ requests simultáneas).  
- **Impacto:** Double-booking posible.  
- **Solución POC:** Cola de procesamiento sincronizada.  
- **Solución Producción:** Locks en DB (`SELECT FOR UPDATE`) o Redis distribuido.  

---

## 💰 Análisis de Costos

### Costos Mensuales Estimados
| Componente     | Tecnología   | Costo POC | Costo Producción |
|----------------|-------------|-----------|-----------------|
| Load Balancer  | Node.js     | $0        | $0              |
| Cache          | In-memory   | $0        | Redis $20-50    |
| Microservicios | Express.js  | $0        | $0              |
| Hosting        | 3 VPS       | $30-45    | $100-150        |
| Monitoreo      | Logs básicos| $0        | Grafana Cloud $0 |
| **TOTAL**      |             | **$30-45**| **$120-200**    |

### Justificación de Decisiones de Costo
- ✗ Redis: innecesario para < 1000 usuarios concurrentes.  
- ✗ API Gateway comercial: simple Round Robin suficiente.  
- ✗ Kubernetes: agrega complejidad y costo.  
- ✗ Cloud Load Balancers: $16+/mes.  

👉 **Resultado: 85% de ahorro vs. solución típica.**  

---

## 📈 Escalabilidad Futura
- **Load Balancer**  
  - Actual: soporta ~500 req/s  
  - Escalar con Nginx para > 1000 req/s  
- **Cache**  
  - Actual: in-memory suficiente  
  - Escalar a Redis > 1000 usuarios simultáneos  
- **Microservicios**  
  - Actual: 2 instancias cada uno  
  - Escalar cuando response > 100ms  

---

## ⚡ Instalación y Ejecución

### Requisitos Previos
- Node.js v18+  
- PowerShell (Windows)  

### Instalación
```bash
# Clonar repositorio
git clone [URL]
cd Tarea-Lab-05---Tech-Stack-for-Architecture

# Instalar dependencias
npm install
```

### Ejecución (5 terminales)
```powershell
# Sales Service 1
$env:PORT=3001; node services/sales-service/index.js

# Sales Service 2
$env:PORT=3011; node services/sales-service/index.js

# Accounting Service 1
$env:PORT=3002; node services/accounting-service/index.js

# Accounting Service 2
$env:PORT=3012; node services/accounting-service/index.js

# Gateway
node gateway.js
```

### Verificación
```powershell
# Health check
curl http://localhost:8080/health

# Ver tickets
curl http://localhost:8080/api/tickets
```

### Ejecutar Tests
```powershell
# Test completo
powershell -ExecutionPolicy Bypass -File tests/run-all-tests.ps1

# Solo load balancing
powershell -ExecutionPolicy Bypass -File tests/load-balancing-test.ps1 -requests 100
```

---

## 📚 Lecciones Aprendidas
1. **Evitar Over-Engineering**  
   - Inicial (IA recomendó): Kong + Redis Cluster + Kubernetes.  
   - Final (implementado): Express Gateway + Cache in-memory.  
   - Ahorro: 85% en costos, 70% menos complejidad.  

2. **Sistemas Distribuidos**  
   - Descubrimiento: Locks en memoria no funcionan entre instancias.  
   - Aprendizaje: Necesidad de herramientas especializadas en producción.  

3. **Métricas antes de Decisiones**  
   - Enfoque: Probar POC antes de elegir tecnologías.  
   - Resultado: Decisiones basadas en datos reales, no suposiciones.  

---

## ✅ Conclusiones
- Tecnologías elegidas con métricas reales.  
- Load balancing: distribución 50-50 perfecta.  
- Performance: < 5ms promedio.  
- Costo: $0 en software.  
- POC implementado y testeado (6/6 tests pasados).  
- Limitaciones identificadas (race conditions) y mitigadas en POC.  

---

## 🧩 Troubleshooting
- **Error: "Cannot connect"**  
  ```powershell
  Get-Process node
  netstat -ano | findstr "8080"
  ```
- **Error: "Port in use"**  
  ```powershell
  Get-Process node | Stop-Process -Force
  ```
- **Error: "ExecutionPolicy"**  
  ```powershell
  powershell -ExecutionPolicy Bypass -File [script.ps1]
  ```

---


