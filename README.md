# OpenTofu Modules for VMware Cloud Director

Репозиторий модулей инфраструктуры как кода для VMware Cloud Director (vCD) на базе OpenTofu.

Основная цель — дать удобные, переиспользуемые и расширяемые модули для практических сценариев эксплуатации vCD.

## Что есть сейчас

- `VMware-VCD/networks-nsxv` — основной сетевой NSX-V модуль (NAT, Firewall, DHCP relay, LB, VPN, edge settings, policy-catalogs).
- `VMware-VCD/vm` — модуль развертывания виртуальных машин в vCD.

## Требования

- OpenTofu `>= 1.9.0, < 2.0.0`
- Provider `vmware/vcd` `>= 3.14.1, < 4.0.0`
- Доступ к vCloud Director API

## Быстрый старт

1. Выбери нужный модуль в `VMware-VCD/*`.
2. Подключи модуль в своем root-конфиге через `source`.
3. Заполни переменные окружения/`tfvars`.
4. Выполни:
   - `tofu init`
   - `tofu validate`
   - `tofu plan`
   - `tofu apply`

## Принципы репозитория

- OpenTofu-first подход
- Provider-only реализация (без внешних скриптов/API workaround по умолчанию)
- Строгие валидации входных данных
- Понятные outputs для автоматизации и последующей композиции модулей

## Важно

Перед применением в production:
- всегда делай `tofu plan`,
- проверяй diff ресурсов,
- тестируй сценарии в отдельной среде.

## Контакты

Автор: Кирилл Жердев  
Telegram: `@Kirill_Digital_2000`, `@K1ru_Haa`