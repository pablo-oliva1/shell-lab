# shell-lab
Una colección de prácticas, pruebas y ejercicios con shell en Linux.

El objetivo es adquirir y perfeccionar habilidades en entornos shell, crear herramientas útiles y documentar las lecciones clave del proceso.

## Prácticas

### En bash shell

#### Mantenimiento

- [mantenimiento_apt.sh](mantenimiento_apt.sh). Menú para consultar, guardar, actualizar y limpiar paquetes de apt y Flatpak. Elimina paquetes huérfanos y limpia el caché de paquetes obsoletos.

#### Discos

- [Reparación de disco](reparar-disco.md). Reparación de disco HDD que presenta problemas a la hora de montarlo en el sistema.
- [Particionado simple](particionado-simple.md). Particionado de un disco de 2TB con una partición formateada en ext4 y otra encriptada con LUKS.

### En fish shell

#### Funciones

- [check_actualizaciones.fish](check_actualizaciones.fish). Pequeña función que permite comprobar todas las actualizaciones disponibles en Pacman, Paru, Yay y Flatpak con un único comando (`comprobar`).

## Documentación

### Tecnologías
- Linux.
- Bash.
- Fish.
- Apt.
- Flatpak.

### Referencias

1. Bash Shell.
    - [dmesg(1) — Linux manual page](https://man7.org/linux/man-pages/man1/dmesg.1.html), en *man7.org*.
    - [NTFS3](https://docs.kernel.org/filesystems/ntfs3.html), en *docs.kernel.org*.
    - [ntfsfix(8)](https://manpages.ubuntu.com/manpages/resolute/man8/ntfsfix.8.html), paquete ntfs-3g, en *manpages.ubuntu.com*.
2. Fish Shell.
    - [Functions](https://fishshell.com/docs/current/language.html#functions), en *fishshell.com*.
    - [Conditions](https://fishshell.com/docs/current/language.html#conditions), en *fishshell.com*.
    

## Licencia

El código y la documentación originales de este repositorio están bajo la licencia [MIT](LICENSE). El material de terceros que aparece en él (salidas de terminal, mensajes de programas, herramientas referenciadas, etc.) mantiene sus propias licencias. Algunas guías incluyen operaciones destructivas sobre discos. Revisa los comandos antes de ejecutarlos y úsalos bajo tu propia responsabilidad.
