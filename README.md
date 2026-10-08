# shell-lab

[Leer en español](README.es.md)

A collection of shell practices, tests and exercises on Linux.

The goal is to build and sharpen skills in shell environments, create useful tools, and document the key lessons learned along the way.

> **Note:** Some scripts, comments or documents in this repository are written in Spanish.

## Practices

### In Bash shell

#### Disks

- [Disk repair](reparar-disco.md). Repair of an HDD that fails to mount on the system.
- [Simple partitioning](particionado-simple.md). Partitioning a 2 TB disk with one partition formatted as ext4 and another encrypted with LUKS.

### In Fish shell

#### Functions

- [check_actualizaciones.fish](check_actualizaciones.fish). A small function that checks all available updates for Pacman, Paru, Yay and Flatpak with a single command (`comprobar`).

## Documentation

### Technologies
- Linux.
- Bash.
- Fish.

### References

1. Bash Shell.
    - [dmesg(1) — Linux manual page](https://man7.org/linux/man-pages/man1/dmesg.1.html), at *man7.org*.
    - [NTFS3](https://docs.kernel.org/filesystems/ntfs3.html), at *docs.kernel.org*.
    - [ntfsfix(8)](https://manpages.ubuntu.com/manpages/resolute/man8/ntfsfix.8.html), ntfs-3g package, at *manpages.ubuntu.com*.
2. Fish Shell.
    - [Functions](https://fishshell.com/docs/current/language.html#functions), at *fishshell.com*.
    - [Conditions](https://fishshell.com/docs/current/language.html#conditions), at *fishshell.com*.

## License

The original code and documentation in this repository are licensed under the [MIT License](LICENSE). Third-party material that appears in it (terminal output, program messages, referenced tools, etc.) remains under its own licenses. Some guides include destructive disk operations. Review the commands before running them and use them at your own risk.
