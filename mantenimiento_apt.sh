#!/bin/bash

OPCION=1
until [ "$OPCION" = 10 ]
do
read -p "
1) Ver actualizaciones del sistema
2) Guardar lista del sistema
3) Actualizar sistema
4) Ver actualizaciones Flatpak
5) Guardar lista Flatpak
6) Actualizar Flatpak
7) Eliminar paquetes huérfanos
8) Limpiar caché
9) Actualizar y limpiar todo
10) Salir

Selección? " OPCION

    case "$OPCION" in
        1) sudo apt update && apt list --upgradable;;
        2) sudo apt update && apt list --upgradable > ~/Documentos/Paquetes_lista.txt && echo "Lista guardada en Documentos";;
        3) sudo apt update && sudo apt upgrade;;
        4) flatpak remote-ls --updates;;
        5) flatpak remote-ls --updates > ~/Documentos/Flatpak_lista.txt && echo "Lista guardada en Documentos";;
        6) flatpak update;;
        7) sudo apt autoremove --purge;;
        8) sudo apt autoclean;;
        9) sudo apt update && sudo apt upgrade && sudo apt autoremove --purge && sudo apt autoclean; flatpak update;;
        10) ;;
        *) echo "Opción inválida";;
    esac
    if [ "$OPCION" != 10 ]; then
        read -p "Pulsa INTRO para continuar"
    fi
done