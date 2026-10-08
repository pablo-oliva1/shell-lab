# Reparación de disco
Ejercicio de diagnóstico y reparación de un disco HDD externo con sistema de archivos NTFS que el sistema no logra montar, usando `dmesg` y `ntfsfix` desde Bash.

## Situación

- Disco HDD de 2 TB.
- Al conectarlo mediante USB al equipo el sistema no consigue montarlo.
- Al intentar montarlo aparece un mensaje de error similar a este:

>*Se produjo un error mientras se accedía a «disco_1», el sistema respondió: La operación solicitada ha fallado: Error mounting /dev/sda2 at /media/user/disco_1: wrong fs type, bad option, bad superblock on /dev/sda2, missing codepage or helper program, or other error.*

## Proceso

El mensaje de error es demasiado genérico como para determinar la causa del problema, pero puede estar relacionado con:
1. La partición no tiene sistema de archivos.
2. El sistema no tiene soporte para ese sistema de archivos.
3. Hay algún problema con el estado del sistema de archivos.
4. Otras opciones no contempladas.

Conviene recordar:
- El núcleo del sistema operativo (kernel) gestiona los recursos del sistema: CPU, memoria, dispositivos, etc.
- Durante sus operaciones el kernel genera mensajes que se almacenan temporalmente.

Dada la falta de concreción sobre el problema una buena opción es consultar la información que pueda haberse registrado en el búfer del kernel.

### dmesg

Es una herramienta que permite consultar los mensajes almacenados en el búfer circular (*ring buffer*) del kernel. Puede consultarse el manual de la herramienta con `man dmesg` [1].

```bash
$ sudo dmesg | tail -20

ntfs3(sda2): It is recommended to use chkdsk.  
ntfs3(sda2): volume is dirty and "force" flag is not set!
```

Vemos que:
1. Se reconoce un sistema de archivos (NTFS).
2. El kernel intentó montar sda2 con ntfs3.
3. El volumen está marcado como sucio (*"volume is dirty"*); quizá no se cerró bien en el último uso.
4. *"Force flag is not set"* señala que no se usó la opción de montaje `force`.

Por lo tanto:
- Se descarta que la partición no tenga sistema de archivos.
- También se descarta que el kernel no esté reconociendo el sistema de archivos.

Un buen paso sería consultar el estado del sistema de archivos.

### ntfsfix

Entre los mensajes encontrados en el búfer uno recomienda el uso de `chkdsk` (herramienta de Windows), y también vemos que se está usando `ntfs3`.

En Linux existen controladores para NTFS como:
- `ntfs3` es un controlador de lectura-escritura integrado en el kernel [2].
- `ntfs-3g` es un controlador en espacio de usuario con herramientas de mantenimiento.

El proyecto `ntfs-3g` incluye `ntfsfix`, que permite operaciones básicas de reparación sobre volúmenes NTFS. Se puede consultar información sobre `ntfsfix` con el comando `man ntfsfix` [3].

Procesos de *ntfsfix*:
- Comprobación y algunas reparaciones del boot sector (sector de arranque del volumen).
- Reinicio de $LogFile (registro de transacciones).
- Limpieza de algunos indicadores (`flags`), como el de volumen sucio con la opción `-d`.

**1. Comprobar que `sda2` no tiene puntos de montaje:**
```bash
$ lsblk -f
```

**2. Instalar el paquete `ntfs-3g`:**
```bash
$ sudo apt install ntfs-3g
```

**3. Ejecutar `ntfsfix`:**
```bash
$ sudo ntfsfix -d /dev/sda2

Mounting volume... OK  
Processing of $MFT and $MFTMirr completed successfully.  
Checking the alternate boot sector... OK  
NTFS volume version is 3.1.  
NTFS partition /dev/sda2 was processed successfully.
```
- Ha procesado correctamente la tabla maestra de archivos (MFT) y su copia de respaldo parcial (MFTMirr).
- Ha comprobado el sector de arranque alternativo.
- No informa de errores durante las operaciones.

### Montaje del disco

```bash
$ sudo mkdir -p /mnt/prueba

$ sudo mount -t ntfs3 /dev/sda2 /mnt/prueba

$ ls -la /mnt/prueba
```

## Conclusión

Tras la ejecución de `ntfsfix` el indicador de *volumen sucio* se borra y puede montarse el volumen.

## Referencias

- [1] [dmesg(1) — Linux manual page](https://man7.org/linux/man-pages/man1/dmesg.1.html), en *man7.org*.
- [2] [NTFS3](https://docs.kernel.org/filesystems/ntfs3.html), en *docs.kernel.org*.
- [3] [ntfsfix(8)](https://manpages.ubuntu.com/manpages/resolute/man8/ntfsfix.8.html), paquete ntfs-3g, en *manpages.ubuntu.com*.
