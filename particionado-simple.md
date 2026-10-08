# Particionado y formateo simple
Ejercicio de particionado simple de un disco de 2 TB (1862 GiB).

## Objetivo

Se hará una partición principal con formato ext4, y otra más reducida encriptada y protegida por contraseña.

Proyecto de partición:

| Partición | Tamaño   | Sistema de archivos |
| --------- | -------- | ------------------- |
| General   | 1812 GiB | ext4                |
| Cifrado   | 50 GiB   | LUKS y ext4         |

Resumen del proceso:

1. Usar el comando `parted` para:
    - Crear tabla de particiones con `mklabel`.
    - Crear particiones con `mkpart`.
    - Comprobar particionado con `print`.
2. Formatear las particiones con `mkfs`.
3. Aplicar el formato LUKS a la partición encriptada con `cryptsetup`.
4. Crear puntos de montaje y montar.

## Proceso

### 1. Crear tabla de particiones GPT en el disco

`parted` es un programa de Linux para crear, eliminar, modificar o analizar particiones. Requiere especificar, tras llamar al programa, sobre qué disco se quiere trabajar, qué operación realizar y (en este caso), qué tabla de particiones hacer.

```
sudo parted <ruta-disco> mklabel gpt
```
`mklabel` (make label) es el subcomando que crea una tabla de particiones, en este caso con una estructura GPT (aplica identificadores GUID únicos a las particiones, soporta discos de gran tamaño, etc.). Otra estructura de particiones posible es MBR (Master Boot Record).

De esta forma:


```bash
$ sudo parted /dev/sda mklabel gpt

Warning: The existing disk label on /dev/sda will be destroyed and all data on this disk will be lost. Do you  
want to continue?  
Yes/No? Yes                                                                  
Information: You may need to update /etc/fstab.
```

### 2. Crear particiones *General* y *Cifrado*

Dentro de las opciones que ofrece `parted` está la de crear particiones dentro de la tabla de particiones del disco, con el subcomando `mkpart`.

```
sudo parted <ruta-disco> mkpart <etiqueta> <formato> <inicio> <fin>
```

`mkpart` no formatea la partición; la declaración que se hace no crea el sistema de archivos.

De esta forma:


```bash
$ sudo parted /dev/sda mkpart General ext4 0% 1812GiB     
Information: You may need to update /etc/fstab.

$ sudo parted /dev/sda mkpart Cifrado 1812GiB 100%  
Information: You may need to update /etc/fstab.
```
- *"0% 1812GiB"* marca el punto de inicio y fin de la partición, en este caso desde el 0% del disco (donde empieza) hasta los primeros 1812 GiB.
- *"1812GiB 100%"* marca el inicio de la segunda partición donde acababa la primera (1812 GiB), y el final donde acaba el disco (tomando el 100% restante).


### 3. Comprobación

Otra de las opciones de `parted` es consultar la información de un disco con `print`, usando la estructura:

```
sudo parted <ruta-disco> print
```

Y de esta forma:

```Bash
$ sudo parted /dev/sda print     
                            
Model: Seagate Expansion SW (scsi)  
Disk /dev/sda: 2000GB  
Sector size (logical/physical): 512B/4096B  
Partition Table: gpt  
Disk Flags:    
  
Number  Start   End     Size    File system  Name     Flags  
1      1049kB  1946GB  1946GB               General  
2      1946GB  2000GB  54,8GB               Cifrado
```

### 4. Formatear particiones (*ext4* y *LUKS*)

Para la primera partición (*General*) se usará el programa `mkfs` con la opción `-L` (label, para designar la etiqueta) y la ruta de la partición.

```
sudo mkfs.<formato> -L <etiqueta> <ruta-partición>
```
Para crear la partición encriptada (*Cifrado*) se usará el programa `cryptsetup` (un programa de línea de comandos para gestionar dispositivos de almacenamiento cifrados). Concretamente se usará LUKS, un estándar para cifrar dispositivos en Linux, con el subcomando `luksFormat` (para configurar LUKS como formato de la partición) y luego se especificará la ruta de partición.

```
sudo cryptsetup luksFormat <ruta-partición>
```

Se puede instalar *cryptsetup* con `sudo apt install cryptsetup`.

De forma que:

```bash
$ sudo mkfs.ext4 -L General /dev/sda1

mke2fs 1.47.2 (1-Jan-2025)  
Creating filesystem with 475004672 4k blocks and 118751232 inodes  
Filesystem UUID: XXXX-XXXX-XXXX-XXXX  
Superblock backups stored on blocks:    
       32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,    
       4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,    
       102400000, 214990848  
  
Allocating group tables: done                               
Writing inode tables: done                               
Creating journal (262144 blocks): done  
Writing superblocks and filesystem accounting information: done

$ sudo cryptsetup luksFormat /dev/sda2  
  
¡ATENCIÓN!  
==========  
Esto sobreescribirá los datos en /dev/sda2 de forma irrevocable.  
  
¿Está seguro? (Teclee 'yes' en mayúsculas): YES  
Introduzca la frase contraseña de /dev/sda2:    
Verifique la frase contraseña:
```

### 5. Aplicar formato *ext4* dentro del espacio formateado con *LUKS*

LUKS no es un sistema de archivos; `sudo cryptsetup luksFormat` no aplica un sistema de archivos (como ext4), sino que genera una capa de cifrado LUKS (un formato de cifrado) sobre una partición. La partición sigue requiriendo un sistema de archivos.

Para esto se usa el subcomando `luksOpen` para abrir el volumen:
```
sudo cryptsetup luksOpen <ruta> <etiqueta>
```

Después se introduce la contraseña del volumen y luego se aplica `mkfs` como se ha usado antes, pero indicando el dispositivo virtual en `/dev/mapper`.

Concepto:
1. El sistema recibe `/dev/sda2`, que contiene el volumen LUKS.
2. Con `cryptsetup luksOpen` se configura la creación de un dispositivo virtual que represente los datos que hay en `sda2`.
3. El `Device Mapper` del kernel crea un dispositivo de bloques virtual.
4. El dispositivo queda disponible en `/dev/mapper/cifrado`.
5. Se aplica el sistema de archivos ext4.

```bash
$ sudo cryptsetup luksOpen /dev/sda2 cifrado  
Introduzca la frase contraseña de /dev/sda2:

$ sudo mkfs.ext4 -L Cifrado /dev/mapper/cifrado

mke2fs 1.47.2 (1-Jan-2025)  
Creating filesystem with 13369344 4k blocks and 3348864 inodes  
Filesystem UUID: XXXX-XXXX-XXXX-XXXX  
Superblock backups stored on blocks:    
       32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,    
       4096000, 7962624, 11239424  
  
Allocating group tables: done                               
Writing inode tables: done                               
Creating journal (65536 blocks): done  
Writing superblocks and filesystem accounting information: done
```
### 6. Montar

- Crear los puntos de montaje (*general* y *cifrado*).
- Montar la primera partición (sda1) en *general*.
- Montar la segunda partición en *cifrado* (ya quedó abierta con *luksOpen*)


```bash
$ sudo mkdir -p /mnt/general /mnt/cifrado

$ sudo mount /dev/sda1 /mnt/general

$ sudo mount /dev/mapper/cifrado /mnt/cifrado
```

### 7. Modificar propietario (si es necesario)

En caso de que los directorios se mantengan con permisos que no permitan su uso como usuario:

```bash
$ sudo chown <usuario>:<usuario> /mnt/general

$ sudo chown <usuario>:<usuario> /mnt/cifrado

$ ls -ld /mnt/general /mnt/cifrado
```

### 8. Desmontar
```bash
$ sudo umount /mnt/general /mnt/cifrado

$ sudo cryptsetup luksClose cifrado
```

Comprobar con `lsblk -f` que los volúmenes no tienen ningún punto de montaje.




