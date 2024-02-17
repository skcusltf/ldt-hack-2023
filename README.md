# 🥈 "Leaders of Digital Transformation" Hackathon, 2023

<p align="center"><a href="/README.ru.md">RU 🇷🇺</a> - <a href="/README.md">EN 🇬🇧</a></p>

## Mobile app to help businesses undergo regulatory inspections

![Preview](/docs/preview.png)

We were tasked with developing a mobile application for the [Open Control](https://knd.mos.ru/) system of the city of Moscow, a part of which provides a simple platform for the communication of businesses and regulatory authorities. To improve the user experience for both of the sides, the mobile app needed to have videoconference support, as well as some form of chat bot, which would help with more typical questions better than an FAQ.

At the end of the hackathon our solution was the most functionally complete, and was rated as second 🥈 in the chosen track, losing in terms of the chatbot's capabilities, which ultimately were one of the main evaluation criteria.

A presentation of our solution is available in the repository: [/docs/presentation.pdf](/docs/presentation.pdf).

### Solution stack

- [Flutter](https://flutter.dev/) as the basis of our cross-platform mobile app
- [Agora](https://www.agora.io/en/) platform for videoconferences
- [Golang](https://go.dev/) for the backend API which manages the whole system
- [PostgreSQL](https://www.postgresql.org/) as our DBMS of choice
- [Rasa](https://rasa.com/), the open source framework for ML-based chat bot development
- [Cloud.ru](https://cloud.ru/ru) for deployment of our services and infrastructure in a cloud [Kubernetes](https://kubernetes.io/) cluster
- [k3d](https://k3d.io/) for local deployment in a minimalistic cluster

### Source code

All source code and configuration files of our solution are available in this repository and are logically structured into directories:

- [/api](/api) — backend gRPC/HTTP API written in Go, providing all of the functionality used by both the mobile application and the administrative website
- [/bot](/bot) — configuration and data used to train the Rasa chat bot
- [/deploy](/deploy) — Helm charts, Dockerfiles, Makefiles used to deploy our infrastructure and services locally and in the cloud
- [/mobile](/mobile) — sources of our crossplatform Flutter-based mobile app

### Team

- [Egor Baranov (@egor-baranov)](https://github.com/egor-baranov): Mobile app, videoconferences
- [Artem Mikheev (@renbou)](https://github.com/renbou): Infrastructure, backend, admin panel, ML-based chat bot
