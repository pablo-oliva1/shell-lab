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
- El propietario es `root` y el grupo `empleados`.
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

Se consulta la información del paquete:

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