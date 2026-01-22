# Инструкция по проверке запуска Stage 0

## Обзор исправлений

### 1. NX Witness Server - Dockerfile (`docker/server/Dockerfile`)

**Проблема:** Контейнер падал с ошибкой `GLIBCXX_3.4.31' not found` из-за старой версии libstdc++ в Ubuntu 22.04.

**Решение:**
- Обновлён базовый образ с `ubuntu:22.04` на `ubuntu:24.04`
- Добавлен пакет `libstdc++-13-dev` для обеспечения совместимости с бинарником NX Witness

**Изменения:**
```dockerfile
FROM ubuntu:24.04  # Было: ubuntu:22.04
...
libstdc++-13-dev   # Добавлено
```

### 2. RTSP камера - MediaMTX конфигурация

**Проблема:** MediaMTX запускался без конфигурации, ошибка `path 'camera' is not configured`, FFmpeg не мог отправить поток.

**Решение:**
- Создан конфигурационный файл `docker/camera/mediamtx.yml` с настроенным путём `camera`
- Обновлён `docker/camera/Dockerfile` для копирования конфигурации в `/etc/mediamtx/mediamtx.yml`
- Скрипт запуска обновлён для использования конфигурационного файла

**Новый файл:** `docker/camera/mediamtx.yml`
```yaml
paths:
  camera:
    source: ffmpeg
    sourceOnDemand: yes
```

### 3. docker-compose.yml - Health Checks

**Добавлены health checks для обоих контейнеров:**

- `nx-server`: проверка HTTP API на порту 7001
- `rtsp-camera`: проверка процессов mediamtx и ffmpeg

### 4. nx-qa.cmd - Проверка конфигурации

**Добавлена проверка существования файла конфигурации MediaMTX перед запуском.**

---

## Инструкция по проверке запуска Stage 0

### Предварительные требования

1. **Docker Desktop** установлен и запущен на Windows 11
2. **NX Witness Server бинарник** находится в директории `nx-binary/`:
   - Файл: `nxwitness-server-6.2.0.42223-linux_x64-private-prod.deb`
3. **Видео файл** (опционально) в директории `video-sources/`:
   - Файл: `test.mp4` (если отсутствует, будет использован синтетический источник)

### Запуск Stage 0

#### Способ 1: Использование скрипта nx-qa.cmd (рекомендуется)

```cmd
nx-qa.cmd
```

Скрипт автоматически:
- Проверит установку Docker
- Проверит наличие бинарника NX Witness
- Проверит конфигурацию MediaMTX
- Соберёт и запустит контейнеры

#### Способ 2: Ручной запуск через docker compose

```cmd
docker compose up -d --build
```

### Проверка работы контейнеров

#### 1. Проверка статуса контейнеров

```cmd
docker compose ps
```

Ожидаемый результат:
```
NAME                 STATUS              PORTS
nx-witness-server    Up (healthy)        0.0.0.0:7001-7003->7001-7003/tcp
rtsp-camera          Up (healthy)        0.0.0.0:8554->8554/tcp
```

#### 2. Проверка логов NX Witness Server

```cmd
docker compose logs nx-server
```

Ожидаемый результат: отсутствие ошибок `GLIBCXX_3.4.31' not found`

#### 3. Проверка логов RTSP камеры

```cmd
docker compose logs rtsp-camera
```

Ожидаемый результат: отсутствие ошибок `path 'camera' is not configured`

#### 4. Проверка health status

```cmd
docker compose ps
```

Оба контейнера должны иметь статус `Up (healthy)`

### Проверка функциональности

#### 1. Проверка NX Witness Server API

```cmd
curl http://localhost:7001/api/health
```

#### 2. Проверка RTSP потока (требуется RTSP плеер)

Используйте VLC Media Player или ffplay:

```cmd
ffplay rtsp://localhost:8554/camera
```

Или в VLC: Медиа → Открыть сетевой поток → `rtsp://localhost:8554/camera`

### Остановка контейнеров

```cmd
docker compose down
```

### Просмотр логов в реальном времени

```cmd
docker compose logs -f
```

---

## Структура исправлённых файлов

```
nx_mvp/
├── docker/
│   ├── server/
│   │   └── Dockerfile          # Исправлен: Ubuntu 24.04 + libstdc++-13-dev
│   └── camera/
│       ├── Dockerfile          # Исправлен: копирование mediamtx.yml
│       └── mediamtx.yml        # Новый файл: конфигурация MediaMTX
├── docker-compose.yml          # Исправлен: добавлены health checks
├── nx-qa.cmd                   # Исправлен: проверка конфигурации MediaMTX
├── nx-binary/
│   └── nxwitness-server-*.deb  # Бинарник NX Witness
└── video-sources/
    └── test.mp4                # Видео файл (опционально)
```

---

## Возможные проблемы и решения

### Проблема: Контейнер nx-server падает

**Решение:** Проверьте логи
```cmd
docker compose logs nx-server
```
Убедитесь, что используется Ubuntu 24.04 и libstdc++-13-dev установлен.

### Проблема: RTSP камера не транслирует

**Решение:** Проверьте логи
```cmd
docker compose logs rtsp-camera
```
Убедитесь, что файл `mediamtx.yml` существует и скопирован в контейнер.

### Проблема: Health check не проходит

**Решение:** Дайте контейнерам больше времени на запуск (start_period в docker-compose.yml)

---

## Успешный запуск

Stage 0 считается успешно запущенным, если:
1. ✅ Оба контейнера имеют статус `Up (healthy)`
2. ✅ NX Witness Server отвечает на HTTP запросы
3. ✅ RTSP поток доступен по адресу `rtsp://localhost:8554/camera`
4. ✅ В логах отсутствуют критические ошибки
