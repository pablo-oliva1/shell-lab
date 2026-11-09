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

