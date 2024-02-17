# Хакатон "Лидеры Цифровой Трансформации", 2023

## Мобильное приложение для прохождения предпринимателями проверок контрольных органов

![Preview](/docs/preview.png)

Задача требовала написания мобильного приложения для платформы [Открытый Контроль](https://knd.mos.ru/) города Москвы, используемой для коммуникации предпринимателей с инспеторами контрольно-надзорных органов, с функционалом чат-бота для ответов на часто-задаваемые вопросы и возможностью проведения видеоконсультаций для предпринимателей и инспекторов.

Презентация нашего решения доступна в репозитории: [/docs/presentation.pdf](/docs/presentation.pdf).

### Стек решения

- Фреймворк [Flutter](https://flutter.dev/) для написания кросс-платформенного мобильного приложения под iOS/Android
- Платформа [Agora](https://www.agora.io/en/) для видеозвонков
- Язык [Golang](https://go.dev/) для бекенд API, управляющей всей системой
- База данных [PostgreSQL](https://www.postgresql.org/)
- Open-source фреймворк для построения умных чат-ботов [Rasa](https://rasa.com/)
- [Cloud.ru](https://cloud.ru/ru) для развёртывания всей инфраструктуры в облачном кластере [Kubernetes](https://kubernetes.io/)
- [k3d](https://k3d.io/v5.6.0/) для развёртывания всей инфраструктуры локально в минималистичном кластере

### Исходный код

Весь исходный код и конфигурационные файлы решения доступны в этом репозитории и логически разбиты по директориям:

- [/api](/api) — gRPC API на Go, предоставляющее всю функциональность пользователям мобильного приложения и административной веб-панели
- [/bot](/bot) — конфигурация и данные для тренировки чат-бота на основании Rasa
- [/deploy](/deploy) — Helm-чарты, Dockerfile'ы, Makefile'ы для развертывания инфраструктуры и сервисов локально и в облаке
- [/mobile](/mobile) — исходный код кроссплатформенного мобильного приложения на Flutter

### Команда

- [Егор Баранов](https://github.com/egor-baranov): Мобильное приложение, видеоконференции
- [Артем Михеев](https://github.com/renbou): Инфраструктура, бекенд, умный чат-бот