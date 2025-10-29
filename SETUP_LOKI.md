# Configuración de Loki para logs de Django y Nginx

## Arquitectura

Este stack de monitoreo (grafana-demo) contiene:
- **Loki**: Sistema de agregación y almacenamiento de logs (puerto 3100)
- **Grafana**: Visualización de logs y métricas (puerto 3000)
- **Prometheus**: Recolección de métricas (puerto 9090)

**Importante**: Promtail NO está aquí. Debe estar en tu proyecto Django donde se generan los logs.

## Componentes instalados

### 1. Loki
- Puerto: 3100
- Endpoint: http://localhost:3100
- Configuración: `loki/loki-config.yml`

### 2. Datasource Loki en Grafana
- Configurado automáticamente en: `grafana/provisioning/datasources/loki.yml`
- URL interna: http://loki:3100

### 3. Dashboard 12559 - "Loki NGINX Service Mesh"
- Ubicación: `grafana/provisioning/dashboards/dashboard-12559.json`
- Visualiza logs de Nginx en formato JSON
- Incluye mapa mundial con geolocalización
- Requiere plugin: grafana-worldmap-panel ✅ (ya instalado)

---

## Cómo integrar tu proyecto Django

Tienes 2 opciones para enviar logs a Loki:

### Opción 1: Django con logging directo + Promtail para Nginx ⭐ (Recomendada)

**Django** envía logs directamente a Loki (sin Promtail)
**Nginx** usa Promtail como sidecar

#### Paso 1: Conecta tu proyecto a la red de grafana-demo

```bash
# En el docker-compose.yml de tu proyecto Django
networks:
  grafana-network:
    external: true
    name: grafana-demo_grafana-network
```

#### Paso 2: Configura Django para enviar logs directos

```bash
# En tu proyecto Django
pip install python-logging-loki
```

Agrega a tu `settings.py`:

```python
import logging_loki

LOGGING = {
    'version': 1,
    'handlers': {
        'loki': {
            'class': 'logging_loki.LokiHandler',
            'url': 'http://loki:3100/loki/api/v1/push',
            'version': '1',
            'tags': {'service': 'django', 'environment': 'production'},
        },
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['loki', 'console'],
        'level': 'INFO',
    },
}
```

#### Paso 3: Agrega Promtail para Nginx

En el `docker-compose.yml` de tu proyecto Django:

```yaml
services:
  nginx:
    volumes:
      - nginx-logs:/var/log/nginx
      - ./nginx.conf:/etc/nginx/nginx.conf

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml
      - nginx-logs:/var/log/nginx:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - grafana-network

volumes:
  nginx-logs:

networks:
  grafana-network:
    external: true
    name: grafana-demo_grafana-network
```

**Configuración de Promtail** (`promtail/promtail-config.yml`):

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: time_local
            status: status
            request_method: request_method
            request_uri: request_uri
            body_bytes_sent: body_bytes_sent
            request_time: request_time
            remote_addr: remote_addr
            http_user_agent: http_user_agent
            http_referer: http_referer
      - labels:
          status:
          request_method:
      - timestamp:
          source: timestamp
          format: "02/Jan/2006:15:04:05 -0700"
```

---

### Opción 2: Todo con Promtail (Enfoque tradicional)

Si prefieres usar Promtail para Django también:

```yaml
services:
  django:
    volumes:
      - app-logs:/app/logs

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml
      - app-logs:/app/logs:ro
      - nginx-logs:/var/log/nginx:ro
    networks:
      - grafana-network
```

Y configura Django para escribir logs a archivo (ver `examples/django-project/django-settings-example.py`).

---

## Configuración de Nginx

Nginx **DEBE** generar logs en formato JSON para que el dashboard funcione.

Edita tu `nginx.conf`:

```nginx
http {
    log_format json_combined escape=json
    '{'
        '"time_local":"$time_local",'
        '"remote_addr":"$remote_addr",'
        '"request":"$request",'
        '"request_method":"$request_method",'
        '"request_uri":"$request_uri",'
        '"status": "$status",'
        '"body_bytes_sent":"$body_bytes_sent",'
        '"request_time":"$request_time",'
        '"http_referer":"$http_referer",'
        '"http_user_agent":"$http_user_agent",'
        '"upstream_response_time":"$upstream_response_time"'
    '}';

    access_log /var/log/nginx/access.log json_combined;
}
```

---

## Iniciar los servicios

```bash
# 1. Inicia el stack de monitoreo (grafana-demo)
cd /path/to/grafana-demo
docker-compose up -d

# 2. Verifica que Loki esté corriendo
curl http://localhost:3100/ready
# Debería responder: ready

# 3. Inicia tu proyecto Django con la configuración actualizada
cd /path/to/tu-proyecto-django
docker-compose up -d
```

---

## Verificación

### 1. Verifica Loki
```bash
curl http://localhost:3100/ready
# Respuesta esperada: ready
```

### 2. Verifica Grafana
- Accede a http://localhost:3000
- Usuario: `admin` / Contraseña: `admin`
- Ve a **Configuration → Data Sources**
- Deberías ver "Loki" con estado verde
- Haz click en **Test** para verificar la conexión

### 3. Verifica el Dashboard
- Ve a **Dashboards → Browse**
- Busca "Loki NGINX Service Mesh" (Dashboard 12559)
- Deberías ver datos después de generar tráfico en tu aplicación

### 4. Explora los logs
- Ve a **Explore**
- Selecciona datasource "Loki"
- Usa queries como:
  ```
  {job="nginx"}
  {job="django"}
  {service="django", level="ERROR"}
  ```

---

## Troubleshooting

### No aparecen logs en Grafana

1. **Verifica que Loki esté recibiendo logs:**
   ```bash
   curl -G -s "http://localhost:3100/loki/api/v1/query" \
     --data-urlencode 'query={job="nginx"}' | jq
   ```

2. **Verifica que Promtail esté corriendo:**
   ```bash
   docker ps | grep promtail
   docker logs <promtail-container-id>
   ```

3. **Verifica que Django esté enviando logs:**
   ```bash
   # Si usas logging directo
   docker logs <django-container-id>
   ```

### Dashboard vacío

- Genera tráfico en tu aplicación (visita algunas URLs)
- Verifica que Nginx esté generando logs en formato JSON:
  ```bash
  docker exec <nginx-container> cat /var/log/nginx/access.log
  ```
- Los logs deben ser JSON, no texto plano

### Error de conexión entre contenedores

- Verifica que ambos proyectos estén en la misma red:
  ```bash
  docker network inspect grafana-demo_grafana-network
  ```
- Deberías ver los contenedores de ambos proyectos listados

---

## Próximos pasos

1. ✅ Loki y Grafana están configurados
2. ✅ Dashboard 12559 está instalado
3. ⏳ Configura tu proyecto Django según Opción 1 o 2
4. ⏳ Configura Nginx para logs JSON
5. ⏳ Genera tráfico y verifica que aparezcan logs
6. 🎯 (Opcional) Instala GeoIP2 para geolocalización en el mapa

---

## Mejoras opcionales

### Geolocalización con GeoIP2

Para que funcione el mapa mundial del dashboard:

1. Descarga la base de datos GeoLite2:
   ```bash
   wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb
   ```

2. Monta en Nginx:
   ```yaml
   nginx:
     volumes:
       - ./GeoLite2-Country.mmdb:/usr/share/GeoIP/GeoLite2-Country.mmdb
   ```

3. Actualiza nginx.conf:
   ```nginx
   http {
       geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
           $geoip_country_code country iso_code;
       }

       log_format json_combined escape=json
       '{'
           # ... otros campos ...
           '"geoip_country_code":"$geoip_country_code"'
       '}';
   }
   ```

---

## Resumen de arquitectura final

```
┌─────────────────────────────────────────┐
│  Tu Proyecto Django (docker-compose)    │
│                                         │
│  ┌─────────┐  ┌───────┐  ┌──────────┐ │
│  │ Django  │  │ Nginx │  │ Promtail │ │
│  │    ↓    │  │   ↓   │  │    ↑     │ │
│  │  logs   │  │ logs  │  │  reads   │ │
│  │ directo │  │  JSON │  │   logs   │ │
│  └────↓────┘  └───↓───┘  └────↓─────┘ │
│       │           │            │        │
└───────│───────────│────────────│────────┘
        │           │            │
        └───────────┴────────────┘
                    ↓
        ┌───────────────────────┐
        │  grafana-network      │
        └───────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  grafana-demo (este proyecto)           │
│                                         │
│  ┌──────┐     ┌─────────┐             │
│  │ Loki │ ←── │ Grafana │              │
│  └──────┘     └─────────┘              │
│                    ↑                    │
│              Dashboard 12559            │
└─────────────────────────────────────────┘
```
