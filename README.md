# NX Witness QA Lab - Stage 0

Минимальная QA лаборатория для тестирования NX Witness Server с виртуальной RTSP камерой.

## Требования

- Windows 11
- Docker Desktop с WSL2 backend
- docker compose v2
- NX Witness Server бинарный файл (.deb)

## Структура проекта

```
nx_mvp/
├── nx-qa.cmd              # Главный скрипт запуска (Windows cmd.exe)
├── docker-compose.yml     # Docker Compose конфигурация
├── docker/
│   ├── server/
│   │   └── Dockerfile     # NX Witness Server контейнер
│   └── camera/
│       └── Dockerfile     # Виртуальная RTSP камера
├── nx-binary/             # Директория для NX Witness бинарного файла
│   └── nxwitness-server-*.deb
└── video-sources/         # Директория для видео файлов
    └── test.mp4
```

## Установка

### 1. Подготовка NX Witness бинарного файла

Поместите NX Witness Server бинарный файл (.deb) в директорию `nx-binary/`.

Имя файла должно соответствовать: `nxwitness-server-6.2.0.42223-linux_x64-private-prod.deb`

Если у вас другое имя файла, отредактируйте `nx-qa.cmd` и `docker/server/Dockerfile`.

### 2. Подготовка видео источника (опционально)

Поместите MP4 файл в директорию `video-sources/` с именем `test.mp4`.

Если видео файл отсутствует, будет использован синтетический источник видео от FFmpeg.

## Использование

### Запуск QA лаборатории

```cmd
nx-qa.cmd
```

Этот скрипт:
1. Проверяет установку Docker
2. Проверяет работу Docker
3. Проверяет доступность docker compose
4. Проверяет наличие NX Witness бинарного файла
5. Запускает контейнеры с помощью `docker compose up -d --build`

### Доступ к сервисам

- **NX Witness Server**: http://localhost:7001
- **RTSP Camera**: rtsp://localhost:8554/camera

### Управление контейнерами

```cmd
# Просмотр логов
docker compose logs -f

# Остановка контейнеров
docker compose down

# Перезапуск контейнеров
docker compose restart

# Просмотр статуса контейнеров
docker compose ps
```

## Тестирование RTSP потока

Для проверки RTSP потока можно использовать VLC Media Player:

1. Откройте VLC
2. Выберите Media → Open Network Stream
3. Введите URL: `rtsp://localhost:8554/camera`
4. Нажмите Play

Или используйте FFmpeg:

```cmd
ffmpeg -rtsp_transport tcp -i rtsp://localhost:8554/camera -f null -
```

## Устранение проблем

### Docker не установлен

```
ERROR: Docker is not installed or not in PATH
Please install Docker Desktop for Windows
```

**Решение**: Установите Docker Desktop для Windows с WSL2 backend.

### Docker не запущен

```
ERROR: Docker is not running
Please start Docker Desktop
```

**Решение**: Запустите Docker Desktop и дождитесь полной инициализации.

### NX Witness бинарный файл не найден

```
ERROR: NX Witness binary not found
Expected location: nx-binary\nxwitness-server-6.2.0.42223-linux_x64-private-prod.deb
```

**Решение**: Поместите .deb файл NX Witness Server в директорию `nx-binary/`.

### Контейнеры не запускаются

Проверьте логи контейнеров:

```cmd
docker compose logs -f
```

## Лицензия

NX Witness Server работает в trial режиме.

## Поддержка

Для вопросов и проблем обращайтесь к команде DevOps.
