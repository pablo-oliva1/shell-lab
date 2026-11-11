# Usuarios y permisos

## Objetivo

Dejar una máquina virtual lista para el trabajo diario de un grupo de trabajo para los siguientes usuarios:

- Berta, responsable de sistemas.
- Ana, contable.
- Jorge, contable.
- Luis, desarrollador.
- Marga, desarrolladora.
- Auditor, auditor externo.

### Requisitos
1.  Una zona de contabilidad en la que solamente los contables pueden escribir y solamente ellos y el auditor pueden leer.
2. Una zona de desarrollo en la que solamente acceden los desarrolladores para leer y escribir.
3. Zona de entregas con una carpeta por empleado en la que solo su dueño puede crear, modificar y borrar archivos. Berta puede leer y gestionar todas las carpetas, pero nadie más accede.
4. Zona pública donde cualquiera puede leer pero solamente Berta puede modificar.
5. El auditor puede leer la zona pública y la de contabilidad pero sin modificar nada, y sin acceder a ninguna otra zona.
6. Berta puede administrar todo el espacio de trabajo con `sudo`.

### Pasos

1. Diseño
    1. Tabla de usuarios y grupos
    2. Matriz de accesos
    3. Estructura de los directorios
    4. Mecanismos de cada zona
2. Configuración de VM
    1. Creación de la administradora
    2. Actualización del sistema
    3. Configuración base de la VM
    4. Instalación y comprobación de herramientas
3. Gestión de paquetes
    1. Búsqueda
    2. Consulta de información
    3. Instalación y actualización
    4. Eliminación
4. Usuarios y grupos
    1. Creación de grupos
    2. Creación de usuarios
    3. Asignación de usuarios a grupos
5. Creación de áreas y permisos
    1. Creación del directorio principal y áreas de trabajo
    2. Grupo, permisos y ACL de *contabilidad*
    3. Grupo, permisos y ACL de *desarrollo*
    4. Permisos de *entregas* y de la subcarpeta de cada empleado
    5. Grupo y permisos de *publica*
6. Comprobación de accesos
    1. Entregas
    2. Desarrollo
    3. Contabilidad
    4. Publica
7. Comprobación de persistencia

## Diseño

### Tabla de usuarios y grupos

| Usuario | Rol | Grupos |
|---------|-------|------|
| Berta | Administración | sudo, empleados | 
| Ana | Contable | contabilidad, empleados |
| Jorge | Contable | contabilidad, empleados |
| Luis | Desarrollador | desarrollo, empleados |
| Marga | Desarrolladora | desarrollo, empleados |
| Auditor | Auditor | Ninguno | 

### Accesos

| Usuario | Contabilidad | Desarrollo | Entregas | Pública |
|---------|--------------|------------|-------|---------|
| Berta | - | - | L, C, Ma, Bp, Ba | L, C, Ma, Bp, Ba |
| Ana | L, C, Ma, Bp, Ba | - | L, C, Bp, Ajenas - | L |
| Jorge | L, C, Ma, Bp, Ba | - | L, C, Bp, Ajenas - | L |
| Luis | - | L, C, Ma, Bp, Ba | L, C, Bp, Ajenas - | L |
| Marga | - | L, C, Ma, Bp, Ba | L, C, Bp, Ajenas - | L |
| Auditor | L | - | - | L |

 ***L**, leer. **C**, crear. **Ma**, modificar archivos ajenos. **Bp**, borrar archivos propios. **Ba**, borrar archivos ajenos. **-**, sin acceso.*

### Estructura de los directorios

Se va a montar la carpeta raíz en `/srv`:
```
/srv/trabajo/
|- contabilidad/
|- desarrollo/
|- entregas/
|   |- ana/
|   |- jorge/
|   |- luis/
|   |- marga/
|- publica/
```

### Mecanismos

Para el directorio general *trabajo*:
- El propietario es `root`.
- Permisos de directorio `rwxr-xr-x`.

En el directorio *contabilidad*:
- El propietario es `root` y el grupo `contabilidad`.
- Permisos de directorio `rwxrwx---`.
- ACL de acceso al auditor (entrar y ver): `user:auditor:r-x`.
- ACL por defecto para permitir lectura/escritura al grupo de los archivos nuevos (`rwX`), y lectura al auditor (`r-X`).

Para el directorio *desarrollo*:
- Propietario `root` y grupo `desarrollo`.
- Permisos de directorio `rwxrwx---` para acceso de los desarrolladores.
- ACL por defecto para permitir lectura/escritura al grupo de los archivos nuevos (`rwX`).

Para el directorio *entregas*:
- Propietario `root`, grupo `empleados` y permisos `rwxr-x---` (750) para que los empleados puedan cruzar el directorio principal y aunque vean las carpetas no puedan crear, borrar o renombrar.
- Para cada subdirectorio el propietario será el empleado dueño, con permisos `rwx------`.
- ACL de acceso a Berta (entra, crea y borra): `user:berta:rwx`.
- ACL por defecto para Berta con `rwX`.

En la carpeta *publica*:
- Propietaria es Berta.
- El permiso del directorio es `rwx---r-x` (705).
- Permisos de archivos `rw-r--r--` (644).

## Configuración en la VM

### Creación de administradora

Se crea el usuario Berta:

```bash
admn@ejercicio:~$ sudo adduser berta
[sudo] contraseña para admn: 
Nueva contraseña: 
Vuelva a escribir la nueva contraseña: 
passwd: contraseña actualizada correctamente
Cambiando la información de usuario para berta
Introduzca el nuevo valor, o pulse INTRO para usar el valor predeterminado
	Nombre completo []: Berta
	Número de habitación []: 1
	Teléfono del trabajo []: 
	Teléfono de casa []: 
	Otro []: 
Is the information correct? [Y/n] Y
```

Se añade a `sudo` y se comprueba:

```bash
admn@ejercicio:~$ sudo adduser berta sudo

admn@ejercicio:~$ su - berta
Contraseña: 

berta@ejercicio:~$ sudo whoami
[sudo] contraseña para berta: 
root
```

Actualización del sistema:

```bash
berta@ejercicio:~$ sudo apt update
Obj:1 http://deb.debian.org/debian trixie InRelease
Des:2 http://deb.debian.org/debian trixie-updates InRelease [47,3 kB]
Des:3 http://security.debian.org/debian-security trixie-security InRelease [43,4 kB]
Des:4 http://security.debian.org/debian-security trixie-security/main Translation-en [181 kB]
Descargados 272 kB en 0s (1.088 kB/s)   
Todos los paquetes están actualizados.  
```

### Ver configuración base

Distribución y versión:

```bash
berta@ejercicio:~$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.7
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

Núcleo:

```bash
berta@ejercicio:~$ uname -r
6.12.116+deb13-amd64
```

Ver administradores:

```bash
berta@ejercicio:~$ getent group sudo
sudo:x:27:admn,berta
```

> **Nota**<br>Se omite comprobación de red.<br>
> En este punto se realiza una instantánea de la VM.

### Instalación de herramientas

Se van a instalar para este ejercicio ACL extendido (`acl`), fun cortafuegos `ufw`, un escáner de puertos `nmap`, acceso remoto (`openssh-server`) y el programa de gestión de particiones.

Se comprueba cuáles estan ya instalados:

```bash
berta@ejercicio:~$ apt list --installed acl ufw nmap openssh-server parted

acl/stable,now 2.3.2-2+b1 amd64 [instalado, automático]
openssh-server/stable,now 1:10.0p1-7+deb13u4 amd64 [instalado, automático]
parted/stable,now 3.6-5 amd64 [instalado, automático]
```

Se instalan los que faltan (salida recortada):
```bash
berta@ejercicio:~$ sudo apt install ufw
Installing:                             
  ufw

berta@ejercicio:~$ sudo apt install nmap
Installing:                             
  nmap
```

### Comprobación de herramientas

```bash
berta@ejercicio:~$ getfacl /srv
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

berta@ejercicio:~$ sudo ufw status
Status: inactive

berta@ejercicio:~$ nmap --version
Nmap version 7.95 ( https://nmap.org )
Platform: x86_64-pc-linux-gnu
Compiled with: liblua-5.4.7 openssl-3.5.7 libssh2-1.11.1 libz-1.3.1 libpcre2-10.46 libpcap-1.10.5 nmap-libdnet-1.12 ipv6
Compiled without:
Available nsock engines: epoll poll select

berta@ejercicio:~$ systemctl status ssh
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-11-09 22:09:48 CET; 28min ago
 Invocation: 928865a593f342dbb99c681ac897018d
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1038 (sshd)
      Tasks: 1 (limit: 4617)
     Memory: 4.9M (peak: 5.6M)
        CPU: 19ms
     CGroup: /system.slice/ssh.service
             └─1038 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Warning: some journal files were not opened due to insufficient permissions.

berta@ejercicio:~$ nmap localhost
Starting Nmap 7.95 ( https://nmap.org ) at 2026-11-09 22:38 CET
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000037s latency).
Other addresses for localhost (not scanned): ::1
Not shown: 998 closed tcp ports (conn-refused)
PORT    STATE SERVICE
22/tcp  open  ssh
631/tcp open  ipp

Nmap done: 1 IP address (1 host up) scanned in 0.02 seconds
```

## Gestión de paquetes

### Elegir un paquete de prueba

En esta parte se va a elegir un paquete, se va a consultar la información del mismo, se va a instalar, se coprobará la instalación y nuevas versiones, se intentará actualizar y luego se eliminará el paquete y sus archivos de configuración.

Se elige el clásico `hello`. Se comprueba primero que no está instalado:

```bash
berta@ejercicio:~$ hello
-bash: hello: orden no encontrada

berta@ejercicio:~$ apt list --installed hello
```

Se busca en `apt`:

```bash
berta@ejercicio:~$ apt search hello
```

Se encuentra como: 

```bash
hello/stable 2.10-5 amd64
  example package based on GNU hello
```

### Consultar información del paquete e instalar

Se consulta:

```bash
berta@ejercicio:~$ apt show hello
Package: hello
Version: 2.10-5
Priority: optional
Section: devel
Maintainer: Santiago Vila <sanvila@debian.org>
Installed-Size: 287 kB
Depends: libc6 (>= 2.38)
Conflicts: hello-traditional
Breaks: hello-debhelper (<< 2.9)
Replaces: hello-debhelper (<< 2.9), hello-traditional
Homepage: https://www.gnu.org/software/hello/
Tag: devel::debian, devel::examples, devel::lang:c, devel::lang:posix-shell,
 devel::packaging, implemented-in::c, interface::commandline,
 role::documentation, role::program, scope::utility, suite::debian,
 suite::gnu
Download-Size: 53,2 kB
APT-Sources: http://deb.debian.org/debian trixie/main amd64 Packages
Description: example package based on GNU hello
 The GNU hello program produces a familiar, friendly greeting.  It
 allows non-programmers to use a classic computer science tool which
 would otherwise be unavailable to them.
 .
 Seriously, though: this is an example of how to do a Debian package.
 It is the Debian version of the GNU Project's `hello world' program
 (which is itself an example for the GNU Project).
```
Se instala (salida recortada):

```bash
berta@ejercicio:~$ sudo apt install hello
Installing:                             
  hello

Summary:
  Upgrading: 0, Installing: 1, Removing: 0, Not Upgrading: 0
  Download size: 53,2 kB
  Space needed: 287 kB / 14,1 GB available
```

El tamaño de la descarga (53,2 kB) y el espacio necesario (287 kB) coinciden con los campos *Download-Size* e *Installed-Size*.

Se comprueba que está instalado:

```bash
berta@ejercicio:~$ apt list --installed hello
hello/stable,now 2.10-5 amd64 [instalado]

berta@ejercicio:~$ hello
¡Hola mundo!
```
### Comprobación y actualización

Se comprueba si hay versión nueva delpaquete:

```bash
berta@ejercicio:~$ sudo apt list --upgradable hello
```

Y se intenta actualizar solamente ese paquete:

```bash
berta@ejercicio:~$ sudo apt install --only-upgrade hello
hello ya está en su versión más reciente (2.10-5).
Summary:
  Upgrading: 0, Installing: 0, Removing: 0, Not Upgrading: 0
```

### Eliminación

Se elimina `hello` y sus archivos de configuración:

```bash
berta@ejercicio:~$ sudo apt purge hello
REMOVING:                               
  hello*

Summary:
  Upgrading: 0, Installing: 0, Removing: 1, Not Upgrading: 0
  Freed space: 287 kB

Continue? [S/n] S
(Leyendo la base de datos ... 136886 ficheros o directorios instalados actualmente.)
Desinstalando hello (2.10-5) ...
Procesando disparadores para man-db (2.13.1-1) ...
```

Comprobar que ya no está:

```bash
berta@ejercicio:~$ hello
-bash: /usr/bin/hello: No existe el fichero o el directorio

berta@ejercicio:~$ apt list --installed hello
```

## Usuarios y grupos

### Creación grupos:

```bash
berta@ejercicio:~$ sudo groupadd contabilidad

berta@ejercicio:~$ sudo groupadd desarrollo

berta@ejercicio:~$ sudo groupadd empleados
```

Para comprobarlo puede usarse el comando de búsqueda de entradas de la bases de datos del sistema:

```bash
berta@ejercicio:~$ getent group contabilidad desarrollo empleados
contabilidad:x:1002:
desarrollo:x:1003:
empleados:x:1004:
```

### Creación de usuarios

Se crean en secuencia (salida recortada):

```bash
berta@ejercicio:~$ sudo adduser ana

berta@ejercicio:~$ sudo adduser jorge

berta@ejercicio:~$ sudo adduser luis

berta@ejercicio:~$ sudo adduser marga

berta@ejercicio:~$ sudo adduser auditor
```

Se comprueba:

```bash
berta@ejercicio:~$ getent passwd ana jorge luis marga auditor
ana:x:1005:1005:Ana,2,,:/home/ana:/bin/bash
jorge:x:1006:1006:Jorge,3,,:/home/jorge:/bin/bash
luis:x:1007:1007:Luis,4,,:/home/luis:/bin/bash
marga:x:1008:1008:Marga,5,,:/home/marga:/bin/bash
auditor:x:1009:1009:Auditor,6,,:/home/auditor:/bin/bash
```

### Agregar usuarios a grupos

```bash
berta@ejercicio:~$ sudo adduser ana contabilidad

berta@ejercicio:~$ sudo adduser ana empleados

berta@ejercicio:~$ sudo adduser jorge contabilidad

berta@ejercicio:~$ sudo adduser jorge empleados

berta@ejercicio:~$ sudo adduser luis desarrollo

berta@ejercicio:~$ sudo adduser luis empleados

berta@ejercicio:~$ sudo adduser marga desarrollo

berta@ejercicio:~$ sudo adduser marga empleados

berta@ejercicio:~$ sudo adduser berta empleados
```

Se comprueba:

```bash
berta@ejercicio:~$ getent group contabilidad
contabilidad:x:1002:ana,jorge

berta@ejercicio:~$ getent group desarrollo
desarrollo:x:1003:luis,marga

berta@ejercicio:~$ getent group empleados
empleados:x:1004:ana,jorge,luis,marga,berta
```

Para aplicar cambios en Berta:

```bash
berta@ejercicio:~$ exit
cerrar sesión

admn@ejercicio:~$ su - berta
Contraseña: 

berta@ejercicio:~$ 
```

## Creación de áreas y permisos

### Crear directorio principal y áreas de trabajo

Se crea el directorio `trabajo` y subdirectorios:

```bash
berta@ejercicio:~$ sudo mkdir /srv/trabajo

berta@ejercicio:~$ sudo mkdir /srv/trabajo/contabilidad

berta@ejercicio:~$ sudo mkdir /srv/trabajo/desarrollo

berta@ejercicio:~$ sudo mkdir -p /srv/trabajo/entregas/ana

berta@ejercicio:~$ sudo mkdir /srv/trabajo/entregas/jorge

berta@ejercicio:~$ sudo mkdir /srv/trabajo/entregas/luis

berta@ejercicio:~$ sudo mkdir /srv/trabajo/entregas/marga

berta@ejercicio:~$ sudo mkdir /srv/trabajo/publica
```

Al crearlas con `sudo` ya cumple con la designación del propietario `root`.

```bash
berta@ejercicio:~$ ls -ld /srv/trabajo
drwxr-xr-x 6 root root 4096 nov  9 23:54 /srv/trabajo
```

Se comprueba que además ya posee los permisos de directorio que se diseñó en el desarrollo de mecanismos. 

No ocurre así con el subdirectorio `contabilidad`:

```bash
berta@ejercicio:~$ ls -ld /srv/trabajo/contabilidad
drwxr-xr-x 2 root root 4096 nov  9 23:53 /srv/trabajo/contabilidad
```
### Grupo y permisos en *contabilidad*
Hay que cambiarle el grupo y los permisos:

```bash
berta@ejercicio:~$ sudo chown root:contabilidad /srv/trabajo/contabilidad

berta@ejercicio:~$ sudo chmod u=rwx,g=rwx,o= /srv/trabajo/contabilidad
```

Ahora debe configurarse ACL en `contabilidad`:
- ACL de acceso para auditor.
- ACL por defecto al grupo.
- ACL por defecto para el auditor.

Se aplica ACL de acceso al auditor:

```bash
berta@ejercicio:~$ sudo setfacl -m u:auditor:r-x /srv/trabajo/contabilidad
```

Se aplica ACL por defecto para permitir lectura y escritura al grupo de los nuevos archivos:

```bash
berta@ejercicio:~$ sudo setfacl -d -m g:contabilidad:rwX /srv/trabajo/contabilidad
```

Se aplica ACL por defecto para permitir lectura al auditor:

```bash
berta@ejercicio:~$ sudo setfacl -d -m u:auditor:r-X /srv/trabajo/contabilidad
```

Se comprueba:

```bash
berta@ejercicio:~$ getfacl /srv/trabajo/contabilidad
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/contabilidad
# owner: root
# group: contabilidad
user::rwx
user:auditor:r-x
group::rwx
mask::rwx
other::---
default:user::rwx
default:user:auditor:r-x
default:group::rwx
default:group:contabilidad:rwx
default:mask::rwx
default:other::---
```

### Grupo y permisos en *desarrollo*

Se aplica grupo y permisos:

```bash
berta@ejercicio:~$ sudo chown root:desarrollo /srv/trabajo/desarrollo

berta@ejercicio:~$ sudo chmod u=rwx,g=rwx,o= /srv/trabajo/desarrollo
```

Se aplica ACL por defecto:

```bash
berta@ejercicio:~$ sudo setfacl -d -m g:desarrollo:rwX /srv/trabajo/desarrollo
```

Se comprueba:

```bash
berta@ejercicio:~$ getfacl /srv/trabajo/desarrollo
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/desarrollo
# owner: root
# group: desarrollo
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:group:desarrollo:rwx
default:mask::rwx
default:other::---
```

### Grupo y permiso en *entregas*

Grupos y permisos:

```bash
berta@ejercicio:~$ sudo chown root:empleados /srv/trabajo/entregas

berta@ejercicio:~$ sudo chmod u=rwx,g=rx,o= /srv/trabajo/entregas
```

Aplicación de grupo, permisos y ACL en la carpeta de Ana:

```bash
berta@ejercicio:~$ sudo chown ana:ana /srv/trabajo/entregas/ana

berta@ejercicio:~$ sudo chmod u=rwx,g=,o= /srv/trabajo/entregas/ana

berta@ejercicio:~$ sudo setfacl -m u:berta:rwx /srv/trabajo/entregas/ana

berta@ejercicio:~$ sudo setfacl -d -m u:berta:rwX /srv/trabajo/entregas/ana

berta@ejercicio:~$ sudo getfacl /srv/trabajo/entregas/ana
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/entregas/ana
# owner: ana
# group: ana
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---
```

Aplicación de grupo, permisos y ACL en la carpeta de Jorge:

```bash
berta@ejercicio:~$ sudo chown jorge:jorge /srv/trabajo/entregas/jorge

berta@ejercicio:~$ sudo chmod u=rwx,g=,o= /srv/trabajo/entregas/jorge

berta@ejercicio:~$ sudo setfacl -m u:berta:rwx /srv/trabajo/entregas/jorge

berta@ejercicio:~$ sudo setfacl -d -m u:berta:rwX /srv/trabajo/entregas/jorge

berta@ejercicio:~$ sudo getfacl /srv/trabajo/entregas/jorge
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/entregas/jorge
# owner: jorge
# group: jorge
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---
```

Aplicación de grupo, permisos y ACL en la carpeta de Luis:

```bash
berta@ejercicio:~$ sudo chown luis:luis /srv/trabajo/entregas/luis

berta@ejercicio:~$ sudo chmod u=rwx,g=,o= /srv/trabajo/entregas/luis

berta@ejercicio:~$ sudo setfacl -m u:berta:rwx /srv/trabajo/entregas/luis

berta@ejercicio:~$ sudo setfacl -d -m u:berta:rwX /srv/trabajo/entregas/luis

berta@ejercicio:~$ sudo getfacl /srv/trabajo/entregas/luis
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/entregas/luis
# owner: luis
# group: luis
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---
```

Aplicación de grupo, permisos y ACL en la carpeta de Marga:

```bash
berta@ejercicio:~$ sudo chown marga:marga /srv/trabajo/entregas/marga

berta@ejercicio:~$ sudo chmod u=rwx,g=,o= /srv/trabajo/entregas/marga

berta@ejercicio:~$ sudo setfacl -m u:berta:rwx /srv/trabajo/entregas/marga

berta@ejercicio:~$ sudo setfacl -d -m u:berta:rwX /srv/trabajo/entregas/marga

berta@ejercicio:~$ sudo getfacl /srv/trabajo/entregas/marga
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/entregas/marga
# owner: marga
# group: marga
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---
```

### Grupo y permiso de *publica*

```bash
berta@ejercicio:~$ sudo chown berta:berta /srv/trabajo/publica

berta@ejercicio:~$ sudo chmod u=rwx,g=,o=rx /srv/trabajo/publica
```

## Comprobar mecánica

### Prueba en carpeta ana

Ana crea un archivo en su carpeta:

```bash
ana@ejercicio:~$ cd /srv/trabajo/entregas/ana

ana@ejercicio:/srv/trabajo/entregas/ana$ nano archivo_ana.txt
```

Jorge intenta acceder y leer el archivo:

```bash
jorge@ejercicio:~$ cd /srv/trabajo/entregas/ana
-bash: cd: /srv/trabajo/entregas/ana: Permiso denegado

jorge@ejercicio:~$ cat /srv/trabajo/entregas/ana/archivo_ana.txt
cat: /srv/trabajo/entregas/ana/archivo_ana.txt: Permiso denegado
```

Berta modifica archivo:

```bash
berta@ejercicio:~$ echo "revisado por berta" >> /srv/trabajo/entregas/ana/archivo_ana.txt
```

### Prueba en carpeta desarrollo

Luis crea un archivo:

```bash
luis@ejercicio:~$ echo "Finalizado" >> /srv/trabajo/desarrollo/final.py
```

Marga lo modifica:

```bash
marga@ejercicio:~$ echo "Confirmo finalización" >> /srv/trabajo/desarrollo/final.py
```

Se comprueba:

```bash
marga@ejercicio:~$ cat /srv/trabajo/desarrollo/final.py
Finalizado
Confirmo finalización
```

Ana no debería poder leerlo:

```bash
marga@ejercicio:~$ getfacl /srv/trabajo/desarrollo/final.py
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/desarrollo/final.py
# owner: luis
# group: luis
user::rw-
group::rwx			#effective:rw-
group:desarrollo:rwx		#effective:rw-
mask::rw-
other::---
```

Ana no debería poder leerlo:

```bash
ana@ejercicio:~$ cat /srv/trabajo/desarrollo/final.py
cat: /srv/trabajo/desarrollo/final.py: Permiso denegado
```

### Prueba en contabilidad

Ana crea un archivo:

```bash
ana@ejercicio:~$ echo "Comprobado" >> /srv/trabajo/contabilidad/factura.txt
```

Jorge modifica:

```bash
jorge@ejercicio:~$ echo "Confirmo comprobación" >> /srv/trabajo/contabilidad/factura.txt
```

Auditor lee:

```bash
auditor@ejercicio:~$ cat /srv/trabajo/contabilidad/factura.txt
Comprobado
Confirmo comprobación
```

Auditor intenta modificar (no debería poder):

```bash
auditor@ejercicio:~$ echo "Hay errores" >> /srv/trabajo/contabilidad/factura.txt
-bash: /srv/trabajo/contabilidad/factura.txt: Permiso denegado
```

Auditor intenta crear un archivo (no debería poder):

```bash
auditor@ejercicio:~$ echo "Aviso de errores" >> /srv/trabajo/contabilidad/aviso.txt
-bash: /srv/trabajo/contabilidad/aviso.txt: Permiso denegado
```

Luis intenta entrar en contabilidad (no debería poder):

```bash
luis@ejercicio:~$ cd /srv/trabajo/contabilidad
-bash: cd: /srv/trabajo/contabilidad: Permiso denegado
```

Comprobar permisos archivo de Ana:

```bash
ana@ejercicio:~$ getfacl /srv/trabajo/contabilidad/factura.txt
getfacl: Eliminando '/' inicial en nombres de ruta absolutos
# file: srv/trabajo/contabilidad/factura.txt
# owner: ana
# group: ana
user::rw-
user:auditor:r-x		#effective:r--
group::rwx			#effective:rw-
group:contabilidad:rwx		#effective:rw-
mask::rw-
other::---
```

### Prueba en publica

Berta crea un archivo:

```bash
berta@ejercicio:~$ echo "Aviso mañana" >> /srv/trabajo/publica/aviso.txt
```

Berta modifica el archivo:

```bash
berta@ejercicio:~$ echo "Sin novedad" >> /srv/trabajo/publica/aviso.txt
```

Ana lee el archivo:

```bash
ana@ejercicio:~$ cat /srv/trabajo/publica/aviso.txt
Aviso mañana
Sin novedad
```

Ana intenta modificarlo (no debería poder):

```bash
ana@ejercicio:~$ echo "De acuerdo" >> /srv/trabajo/publica/aviso.txt
-bash: /srv/trabajo/publica/aviso.txt: Permiso denegado
```

Ana crea un archivo (no debería poder):

```bash
ana@ejercicio:~$ echo "Aviso recibido" >> /srv/trabajo/publica/ok.txt
-bash: /srv/trabajo/publica/ok.txt: Permiso denegado
```

Auditor intenta leer:

```bash
auditor@ejercicio:~$ cat /srv/trabajo/publica/aviso.txt
Aviso mañana
Sin novedad
```

## Comprobar persistencia

Se hace un reinicio:

```bash
berta@ejercicio:~$ sudo reboot now
```

Y se comprueba persistencia:

```bash
berta@ejercicio:~$ ls -ld /srv/trabajo /srv/trabajo/publica
drwxr-xr-x 6 root  root  4096 nov  9 23:54 /srv/trabajo
drwx---r-x 2 berta berta 4096 nov 10 23:44 /srv/trabajo/publica

berta@ejercicio:~$ sudo getfacl -p /srv/trabajo/contabilidad /srv/trabajo/desarrollo /srv/trabajo/entregas /srv/trabajo/entregas/*
[sudo] contraseña para berta: 
# file: /srv/trabajo/contabilidad
# owner: root
# group: contabilidad
user::rwx
user:auditor:r-x
group::rwx
mask::rwx
other::---
default:user::rwx
default:user:auditor:r-x
default:group::rwx
default:group:contabilidad:rwx
default:mask::rwx
default:other::---

# file: /srv/trabajo/desarrollo
# owner: root
# group: desarrollo
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:group:desarrollo:rwx
default:mask::rwx
default:other::---

# file: /srv/trabajo/entregas
# owner: root
# group: empleados
user::rwx
group::r-x
other::---

# file: /srv/trabajo/entregas/ana
# owner: ana
# group: ana
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---

# file: /srv/trabajo/entregas/jorge
# owner: jorge
# group: jorge
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---

# file: /srv/trabajo/entregas/luis
# owner: luis
# group: luis
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---

# file: /srv/trabajo/entregas/marga
# owner: marga
# group: marga
user::rwx
user:berta:rwx
group::---
mask::rwx
other::---
default:user::rwx
default:user:berta:rwx
default:group::---
default:mask::rwx
default:other::---

berta@ejercicio:~$ sudo -u jorge cat /srv/trabajo/contabilidad/factura.txt
Comprobado
Confirmo comprobación
```