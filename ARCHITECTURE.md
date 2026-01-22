# NX Witness QA Lab - Architecture Overview

## Обзор архитектуры

NX Witness QA Lab - это минимальная тестовая среда для автоматизированного тестирования NX Witness Server с виртуальной RTSP камерой. Система полностью автономна и работает офлайн.

## Компоненты системы

### 1. nx-qa.cmd (Точка входа)

**Назначение**: Единственная точка входа для запуска QA лаборатории на Windows.

**Ответственности**:
- Проверка установки Docker
- Проверка работы Docker daemon
- Проверка доступности docker compose
- Проверка наличия NX Witness бинарного файла
- Запуск docker compose up -d --build
- Отображение сообщений об успехе/ошибке
- Возврат соответствующего errorlevel

**Ограничения**:
- Только Windows cmd.exe
- Никакой логики bash, sh или PowerShell
- Только оркестрация Docker

### 2. Docker Compose (docker-compose.yml)

**Назначение**: Оркестрация контейнеров NX Witness Server и виртуальной камеры.

**Сервисы**:

#### nx-server
- **Базовый образ**: Ubuntu 22.04
- **Порты**:
  - 7001: HTTP API
  - 7002: HTTPS API
  - 7003: Media port
- **Volumes**:
  - nx-data: Данные NX Witness Server
- **Сеть**: nx-network (bridge)
- **Рестарт**: unless-stopped

#### rtsp-camera
- **Базовый образ**: Ubuntu 22.04
- **Порт**: 8554 (RTSP)
- **Volumes**:
  - ./video-sources:/video-sources:ro (только чтение)
- **Переменные окружения**:
  - RTSP_PORT=8554
  - CAMERA_NAME=camera
- **Сеть**: nx-network (bridge)
- **Рестарт**: unless-stopped

### 3. NX Witness Server Container (docker/server/Dockerfile)

**Назначение**: Контейнер для запуска NX Witness Server.

**Особенности**:
- Ubuntu 22.04 с необходимыми зависимостями
- Установка NX Witness Server из .deb пакета
- Отсутствие systemd (запуск через скрипт)
- Trial режим работы
- Linux x86_64 архитектура

**Зависимости**:
- X11 библиотеки
- GL библиотеки
- GTK3
- ALSA
- Wayland
- И другие системные библиотеки

**Запуск**:
- Скрипт /start-nxwitness.sh
- Параметры: --no-sandbox, --disable-gpu, --headless
- Фоновый режим работы

### 4. Virtual RTSP Camera Container (docker/camera/Dockerfile)

**Назначение**: Контейнер для виртуальной RTSP камеры.

**Особенности**:
- Ubuntu 22.04 с FFmpeg
- RTSP сервер на порту 8554
- Поддержка локальных MP4 файлов
- Синтетический видео источник как fallback
- Полностью офлайн работа

**Источники видео (приоритет)**:
1. Локальный MP4 файл из ./video-sources/test.mp4
2. Синтетический источник FFmpeg (testsrc)

**Параметры потока**:
- Кодек: H.264 (libx264)
- Пресет: ultrafast
- Tune: zerolatency
- Без аудио

## Поток данных

```
┌─────────────────┐         ┌─────────────────┐
│   nx-qa.cmd     │────────▶│  Docker Compose │
│  (Windows)      │         │                 │
└─────────────────┘         └────────┬────────┘
                                     │
                                     ▼
                          ┌────────────────────┐
                          │   Docker Daemon    │
                          └────────┬───────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
          ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
          │ NX Witness   │  │ RTSP Camera  │  │  nx-data     │
          │   Server     │  │   (FFmpeg)   │  │   Volume     │
          │  Port 7001   │  │  Port 8554   │  │              │
          └──────────────┘  └──────────────┘  └──────────────┘
                    │              │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ nx-network   │
                    │   (bridge)   │
                    └──────────────┘
```

## Сетевая архитектура

### nx-network (Bridge Network)

- **Тип**: bridge
- **Назначение**: Изолированная сеть для коммуникации между контейнерами
- **Участники**:
  - nx-server
  - rtsp-camera

### Доступ к сервисам с хоста

- NX Witness Server: http://localhost:7001
- RTSP Camera: rtsp://localhost:8554/camera

## Хранение данных

### nx-data Volume

- **Тип**: Docker volume
- **Назначение**: Хранение данных NX Witness Server
- **Монтирование**: /opt/networkoptix/nxwitness-server/data
- **Персистентность**: Да (сохраняется между перезапусками)

### video-sources Directory

- **Тип**: Bind mount (только чтение)
- **Назначение**: Хранение видео файлов для RTSP камеры
- **Монтирование**: /video-sources:ro
- **Персистентность**: Да (файлы на хосте)

## Безопасность

### Изоляция

- Контейнеры изолированы друг от друга
- Отдельная bridge сеть (nx-network)
- Bind mount только для чтения (video-sources)

### Ограничения

- NX Witness Server работает в trial режиме
- Нет доступа к интернету (полностью офлайн)
- Минимальные привилегии контейнеров

## Производительность

### Ресурсы

- Минимальные системные требования:
  - 4 GB RAM (рекомендуется 8 GB)
  - 2 CPU cores (рекомендуется 4)
  - 10 GB свободного дискового пространства

### Оптимизация

- FFmpeg preset: ultrafast (минимальная задержка)
- Tune: zerolatency (для RTSP стриминга)
- Без аудио (экономия ресурсов)

## Расширяемость

### Добавление камер

Для добавления дополнительных камер:

1. Добавить новый сервис в docker-compose.yml
2. Изменить порт RTSP (например, 8555, 8556, ...)
3. Изменить CAMERA_NAME (например, camera2, camera3, ...)
4. Добавить дополнительные видео файлы в video-sources/

### Добавление видео источников

Для добавления новых видео источников:

1. Поместить MP4 файлы в ./video-sources/
2. Изменить VIDEO_FILE переменную в docker/camera/Dockerfile
3. Пересобрать контейнер: docker compose up -d --build rtsp-camera

## Диагностика

### Логи контейнеров

```cmd
docker compose logs -f nx-server
docker compose logs -f rtsp-camera
docker compose logs -f
```

### Статус контейнеров

```cmd
docker compose ps
```

### Проверка RTSP потока

```cmd
ffmpeg -rtsp_transport tcp -i rtsp://localhost:8554/camera -f null -
```

## Ограничения Stage 0

- Только одна виртуальная камера
- Только один NX Witness Server
- Нет UI тестов
- Нет CI/CD интеграции
- Нет dashboards
- Нет load testing
- Полностью офлайн работа
- Только Windows 11

## Следующие этапы (Stage 1+)

- Множество виртуальных камер
- Автоматизированные UI тесты
- CI/CD интеграция
- Monitoring и dashboards
- Load testing
- Кроссплатформенность (Linux, macOS)
