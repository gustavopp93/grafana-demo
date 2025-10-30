# Grafana Monitoring Stack

Stack completo de monitoreo y visualización con Grafana, InfluxDB, Prometheus y Loki.

## 🎯 Componentes

Este repositorio proporciona la infraestructura de monitoreo para múltiples fuentes de datos:

- **InfluxDB**: Base de datos de series temporales para métricas de k6
- **Prometheus**: Sistema de monitoreo y alerta para métricas de aplicaciones
- **Loki**: Agregación y consulta de logs
- **Tempo**: Sistema de trazado distribuido para traces de aplicaciones
- **Grafana**: Plataforma de visualización y dashboards

## 🚀 Inicio Rápido

### 1. Configurar variables de entorno (opcional)

```bash
cp .env.example .env
```

Edita `.env` si necesitas cambiar las credenciales por defecto.

### 2. Iniciar el stack completo

```bash
./start-monitoring.sh
```

Esto iniciará todos los servicios:
- InfluxDB en puerto 8086
- Prometheus en puerto 9090
- Loki en puerto 3100
- Tempo en puertos 3200 (HTTP), 4318 (OTLP HTTP)
- Grafana en puerto 3000

### 3. Acceder a Grafana

Abre tu navegador en: http://localhost:3000

- **Usuario**: admin (por defecto)
- **Password**: admin (por defecto)

## 📊 Datasources Configurados

Los siguientes datasources están pre-configurados automáticamente:

### InfluxDB (k6 Metrics)
- **URL**: http://influxdb:8086
- **Organization**: k6-org
- **Bucket**: k6-metrics
- **Token**: Configurado via variables de entorno
- **Uso**: Métricas de pruebas de carga de k6

### Prometheus
- **URL**: http://prometheus:9090
- **Uso**: Métricas de aplicaciones y sistema

### Loki
- **URL**: http://loki:3100
- **Uso**: Logs agregados de aplicaciones

### Tempo
- **URL**: http://tempo:3200
- **OTLP HTTP Endpoint**: tempo:4318
- **Uso**: Trazado distribuido (distributed tracing) con OpenTelemetry
- **Integración**: Conectado con Loki (traces a logs) y Prometheus (métricas)

## 📈 Dashboards Incluidos

### k6 Load Testing Dashboard
Dashboard pre-configurado para visualizar métricas de k6:
- Virtual Users activos
- Tiempos de respuesta HTTP
- Request rate
- Errores y fallos
- Throughput

**Ubicación**: Disponible automáticamente en Grafana > Dashboards > k6 Load Testing

## 🔗 Integración con otros repositorios

### k6-demo
El repositorio `k6-demo` está configurado para enviar métricas a este stack:

1. Inicia este stack de monitoreo primero:
   ```bash
   ./start-monitoring.sh
   ```

2. Ve al repositorio k6-demo y ejecuta tus tests:
   ```bash
   cd ../k6-demo
   ./run-smoke-test.sh
   ```

3. Los resultados aparecerán automáticamente en Grafana

### django-quality-demo
Configura tu aplicación Django para enviar métricas a Prometheus o logs a Loki.

### Alloy (OpenTelemetry Collector)
Para enviar traces a Tempo desde otro proyecto usando Alloy:

1. En tu proyecto con Alloy, configura el exporter OTLP HTTP apuntando a este Tempo:
   ```yaml
   otelcol.exporter.otlphttp "tempo" {
     client {
       endpoint = "http://localhost:4318"
     }
   }
   ```

2. Las trazas enviadas aparecerán automáticamente en Grafana > Explore > Tempo

## 📁 Estructura del Proyecto

```
grafana-demo/
├── docker-compose.yml              # Configuración de servicios
├── .env.example                    # Variables de entorno de ejemplo
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/           # Datasources pre-configurados
│   │   │   ├── influxdb.yml       # Configuración InfluxDB
│   │   │   ├── prometheus.yml     # Configuración Prometheus
│   │   │   └── loki.yml           # Configuración Loki
│   │   └── dashboards/            # Provisión de dashboards
│   │       └── k6-dashboard.yml   # Config del dashboard de k6
│   └── dashboards/                # Archivos JSON de dashboards
│       └── k6-dashboard.json      # Dashboard de k6
├── prometheus/
│   └── prometheus.yml             # Configuración de Prometheus
├── loki/
│   └── loki-config.yml            # Configuración de Loki
├── tempo/
│   └── tempo-config.yml           # Configuración de Tempo
├── start-monitoring.sh            # Inicia todos los servicios
└── stop-monitoring.sh             # Detiene todos los servicios
```

## 🔧 Configuración Avanzada

### Variables de Entorno

Puedes personalizar la configuración editando el archivo `.env`:

```bash
# InfluxDB
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=admin123456
INFLUXDB_ORG=k6-org
INFLUXDB_BUCKET=k6-metrics
INFLUXDB_TOKEN=k6-admin-token-secret

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

**Importante**: Si cambias estas variables, asegúrate de actualizar también el archivo `.env` en el repositorio `k6-demo`.

### Agregar Nuevos Datasources

1. Crea un nuevo archivo YAML en `grafana/provisioning/datasources/`
2. Reinicia el stack: `./stop-monitoring.sh && ./start-monitoring.sh`

### Agregar Nuevos Dashboards

1. Crea tu dashboard en Grafana UI
2. Exporta el dashboard como JSON
3. Guarda el archivo en `grafana/dashboards/`
4. Crea un archivo de provisión en `grafana/provisioning/dashboards/`

## 🧹 Limpieza

### Detener servicios (mantener datos)
```bash
./stop-monitoring.sh
```

### Detener y eliminar todos los datos
```bash
docker compose down -v
```

## 🐛 Troubleshooting

### InfluxDB no inicia correctamente
- Verifica que el puerto 8086 no esté en uso: `lsof -i :8086`
- Revisa los logs: `docker compose logs influxdb`

### Grafana no muestra datos de k6
- Verifica que InfluxDB esté corriendo: `docker compose ps`
- Revisa el datasource de InfluxDB en Grafana > Configuration > Data sources
- Asegúrate de que el token, org y bucket coincidan entre ambos repos

### No puedo acceder a Grafana
- Verifica que el puerto 3000 no esté en uso
- Espera unos segundos después de iniciar: `docker compose logs grafana`

### Prometheus no encuentra targets
- Verifica la configuración en `prometheus/prometheus.yml`
- Asegúrate de que los servicios target estén corriendo

## 📊 Puertos Utilizados

- **3000**: Grafana UI
- **3100**: Loki API
- **3200**: Tempo HTTP API
- **4318**: Tempo OTLP HTTP (para envío de traces desde Alloy u otros collectors)
- **8086**: InfluxDB API
- **9090**: Prometheus UI

Asegúrate de que estos puertos estén disponibles antes de iniciar el stack.

## 📝 Próximos Pasos

1. Configura alertas en Grafana para métricas críticas
2. Crea dashboards personalizados para tus aplicaciones
3. Integra más servicios con Prometheus y Loki
4. Explora las capacidades de query de cada datasource

## 📚 Recursos

- [Grafana Documentation](https://grafana.com/docs/)
- [InfluxDB Documentation](https://docs.influxdata.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [k6 Documentation](https://k6.io/docs/)
