# Aspia Server Docker (v3.0.20)

Раздельные Docker-образы для **Aspia Router** и **Aspia Relay** с автоматической инициализацией и управлением конфигурацией через переменные окружения.

Форк проекта [paprikkafox/aspia-server-docker](https://github.com/paprikkafox/aspia-server-docker)

> ⚠️ Версия 3.x несовместима с образами `paprikkafox/aspia-server` (v2.7). Архитектура, порты и формат конфигурации изменились. См. [официальную документацию по миграции](https://aspia.org/docs/migration).

## Образы

| Образ | Описание |
|---|---|
| `docker.io/crystalvega/aspia-router:3.0.20` | Маршрутизатор: управление хостами, клиентами, релеями, STUN |
| `docker.io/crystalvega/aspia-relay:3.0.20` | Ретранслятор: транзит трафика между пирами |

## Быстрый старт

```bash
git clone <repo-url> && cd aspia-server-docker
# Отредактируйте RELAY_PUBLIC_ADDRESS в docker-compose.yml
docker compose up -d
docker compose logs aspia-router   # ← ключи и credentials
```

При первом запуске:
1. **Router** генерирует конфигурацию, ключи и учётную запись `admin/admin`.
2. **Relay** ожидает ключ от Router, затем автоматически создаёт `relay.conf`.
3. Все порты и параметры берутся из переменных окружения в `docker-compose.yml`.

При перезапуске контейнера entrypoint **автоматически обновляет** конфигурационные файлы, если значения переменных изменились. Ключи и база данных не затрагиваются.

## Переменные окружения

### Router

| Переменная | По умолчанию | Описание |
|---|---|---|
| `ASPIA_LOG_TO_STDOUT` | `1` | Вывод логов в stdout |
| `ASPIA_LOG_LEVEL` | `2` | Уровень логирования (0=trace, 1=info, 2=warning, 3=error, 4=fatal) |
| `ASPIA_HOST_PORT` | `8061` | Порт для хостов ≥ 3.0 |
| `ASPIA_HOST_LEGACY_PORT` | `8060` | Порт для хостов < 3.0 |
| `ASPIA_CLIENT_PORT` | `8062` | Порт для клиентов |
| `ASPIA_RELAY_PORT` | `8063` | Порт для релеев |
| `ASPIA_STUN_PORT` | `8065` | Порт STUN-сервера (UDP) |

### Relay

| Переменная | По умолчанию | Описание |
|---|---|---|
| `RELAY_PUBLIC_ADDRESS` | — | Внешний IP для подключения пиров (**обязательно**) |
| `ROUTER_ADDRESS` | `aspia-router` | Адрес Router (имя сервиса в compose) |
| `RELAY_PEER_PORT` | `8070` | Порт для трафика пиров |
| `RELAY_ROUTER_PORT` | `8063` | Порт подключения к Router (должен совпадать с `ASPIA_RELAY_PORT`) |
| `RELAY_IDLE_TIMEOUT` | `5` | Таймаут простоя пиров (минуты, 1–60) |
| `RELAY_MAX_COUNT` | `100` | Максимум одновременных соединений (1–1000) |
| `ASPIA_LOG_TO_STDOUT` | `1` | Вывод логов в stdout |
| `ASPIA_LOG_LEVEL` | `2` | Уровень логирования (0–4) |

> 💡 Порты в секции `ports:` docker-compose используют те же переменные, поэтому маппинг всегда соответствует внутренней конфигурации сервисов.

## Структура данных

```
data/
├── router/
│   ├── config/      # router.conf, host.pub, relay.pub
│   └── database/    # router.db3 (SQLite)
├── relay/
│   └── config/      # relay.conf (автогенерируется)
└── shared-keys/     # обмен ключами между сервисами
```

## Смена пароля

Пароль по умолчанию: `admin / admin`.
Смените при первом подключении через Aspia Client v3.x. Двухфакторная аутентификация обязательна.

## Сборка образов

```bash
docker compose build
```

Или через CI/CD (Gitea Actions) — см. `.github/workflows/docker-image.yml`.

## Обновление версии

1. Измените `ASPIA_VERSION` в обоих Dockerfile и в `.github/workflows/docker-image.yml`.
2. Запустите пайплайн или пересоберите вручную.
3. Обновите тег образа в `docker-compose.yml`.
4. Выполните `docker compose pull && docker compose up -d`.

Конфигурация и база данных мигрируются автоматически при первом запуске новой версии.

## Полезные ссылки

- [Официальный сайт Aspia](https://aspia.org/)
- [Документация по миграции v2 → v3](https://aspia.org/docs/migration)
- [Документация Router](https://aspia.org/docs/router)
- [Документация Relay](https://aspia.org/docs/relay)
- [Исходный код Aspia](https://github.com/dchapyshev/aspia)

## Лицензия

GNU General Public License v3.0

Автор Aspia — [Dmitry Chapyshev](https://github.com/dchapyshev)
Docker-образы v3.x — внутренняя сборка SZMA-Inform
