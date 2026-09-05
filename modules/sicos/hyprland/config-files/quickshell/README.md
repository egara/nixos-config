# Proyecto: SicOS Custom Bar (basada en QuickShell)

## 🎯 Objetivo del Proyecto
Crear una barra de sistema (panel superior) nativa y totalmente customizada para el entorno de escritorio **SicOS**, utilizando **QuickShell** (el mismo framework subyacente que usa Dank Material Shell o el proyecto Omarchy). 

El objetivo es reemplazar (o tener como alternativa de primer nivel) a `waybar` y `dank-material-shell`, manteniendo un diseño estético idéntico al actual de DMS, pero con un control total sobre el código fuente (QML) e integración completa con **Stylix** para el modo claro/oscuro.

## 🏗️ Arquitectura y Archivos Clave
La integración se realiza directamente en los módulos de NixOS y Home Manager de SicOS.

- **`modules/sicos/hyprland/default.nix`**: Define la nueva opción `cfg.shell == "sicos-bar"`. Cuando se selecciona, añade el paquete `quickshell` al entorno.
- **`modules/sicos/hyprland/hm-module.nix`**: Genera dinámicamente el archivo de configuración `~/.config/quickshell/shell.qml`. También modifica el script de arranque (`start-shell.sh`) para lanzar QuickShell mediante `uwsm app -- quickshell &`.
- **`home-manager/desktop/hyprland/scripts/theme-switcher.sh`**: Gestiona el cambio de tema claro/oscuro. Si QuickShell está en ejecución, este script lo reinicia (`pkill quickshell`) para que QML pueda recargar los nuevos colores generados por Stylix.
- **`modules/sicos/hyprland/config-files/quickshell/quickshell-bar.nix`**: La plantilla principal de Nix que genera el código QML de la barra. Aquí es donde se inyectan dinámicamente:
  - Las fuentes globales de Stylix (`config.stylix.fonts.monospace.name`).
  - Los colores de Stylix (`config.lib.stylix.colors.base00`, `base05`, etc.).

## 🚀 Progreso Actual
- [x] **Setup Inicial:** Configuración de `default.nix`, `hm-module.nix` y `theme-switcher.sh` completada.
- [x] **Maquetación Base (QML):** Diseño flotante y transparente, respetando los colores y la tipografía con bordes redondeados.
- [x] **Módulo Reloj:** Integrado usando `Qt.formatDateTime` con el mismo formato que DMS (`ddd MMM d hh:mm`).
- [x] **Módulo Lanzador y Apagado:** Botones funcionales con íconos, usando `Quickshell.Io (Process)` para invocar `walker` y `wlogout`.
- [x] **Módulo Workspaces:** Integración nativa con `Quickshell.Hyprland`. Detecta escritorios activos, permite clics para navegar entre ellos (`Hyprland.dispatch`) e incluye animaciones dinámicas.
- [x] **Módulo Batería:** Integración nativa con `Quickshell.Services.UPower`. Lee el estado y porcentaje real de la batería (multiplicando `percentage * 100` por ser un float 0.0-1.0). Se oculta en dispositivos de sobremesa.
- [x] **Módulo Escalado de Monitor (Control Center):** Integración en el centro de control (`controlcenter.nix`) de un pill desplegable con icono Nerdfont (`󰍹`), nombre/escala de monitores detectados, botones `-`/`+` y slider continuo. Ejecuta `sicos-monitor-scale.sh` para aplicar cambios en vivo en Hyprland/Kanshi y persistirlos dinámicamente en el repositorio sin requerir `nixos-rebuild switch`.

## 🚧 Siguientes Pasos
1. **Módulo de Sistema (CPU/RAM):** Diseñar un sistema para leer `/proc/stat` y `/proc/meminfo` (o ejecutar comandos `free` / `top` periódicamente vía `Process`) para mostrar el uso real.
2. **System Tray (Bandeja del sistema):** Integrar `Quickshell.Services.SystemTray` para mostrar íconos minimizados de aplicaciones como Insync, NetworkManager, etc.
3. **Control Multimedia (Opcional):** Mostrar la música actual usando la API nativa de MPRIS de QuickShell.
4. **Notificaciones / Panel de control:** Integrar `swaync` o crear un panel lateral propio en QML.
