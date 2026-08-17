# Proyecto: SicOS Custom Bar (basada en QuickShell)

## 🎯 Objetivo del Proyecto
Crear una barra de sistema (panel superior) nativa y totalmente customizada para el entorno de escritorio **SicOS**, utilizando **QuickShell** (el mismo framework subyacente que usa Dank Material Shell o el proyecto Omarchy). 

El objetivo es reemplazar (o tener como alternativa de primer nivel) a `waybar` y `dank-material-shell`, manteniendo un diseño estético idéntico al actual de DMS, pero con un control total sobre el código fuente (QML) e integración completa con **Stylix** para el modo claro/oscuro.

## 🏗️ Arquitectura y Archivos Clave
La integración se realiza directamente en los módulos de NixOS y Home Manager de SicOS, utilizando un **enfoque modular basado en Nix String Interpolation**. Esto permite mantener el código QML organizado, limpio y completamente reactivo a Stylix.

- **`modules/sicos/hyprland/default.nix`**: Define la nueva opción `cfg.shell == "sicos-bar"`. Cuando se selecciona, añade el paquete `quickshell` al entorno.
- **`modules/sicos/hyprland/hm-module.nix`**: Genera dinámicamente el archivo de configuración `~/.config/quickshell/shell.qml`.
- **`home-manager/desktop/hyprland/scripts/theme-switcher.sh`**: Gestiona el cambio de tema claro/oscuro reiniciando QuickShell (`uwsm app`) para aplicar los nuevos colores de Stylix al instante.

### 🧩 Componentes Modulares (Nix + QML)
Para evitar archivos monolíticos gigantescos, la barra se compone de un archivo principal que importa e inyecta submódulos QML mediante variables de Nix. Esto facilita enormemente el mantenimiento y escalabilidad.

- **`quickshell-bar.nix`**: El "esqueleto" principal. Define la ventana (`PanelWindow`), el fondo flotante y gestiona el layout organizando y renderizando los componentes inyectados.
- **Directorio `components/`**: Contiene submódulos independientes:
  - `battery.nix`: Lógica avanzada de batería (`UPower`), cálculo de tiempo restante, detección del 80% límite de carga por BIOS y animaciones del *Popout Window*.
  - `clock.nix`: Reloj central en tiempo real (`Qt.formatDateTime`).
  - `power.nix`: Selector dinámico de *Power Profiles* y botón de sesión interactuando con subprocesos del sistema (`powerprofilesctl`).
  - `system.nix`: Botón lanzador de aplicaciones (`walker`) y *placeholders* visuales de CPU y RAM.
  - `workspaces.nix`: Integración nativa bidireccional con Hyprland (`Quickshell.Hyprland`). Identifica dinámicamente las ventanas abiertas en cada escritorio renderizando su icono del sistema y agrupándolas inteligentemente mediante una heurística de *class* y *título*.
## 🚀 Progreso Actual
- [x] **Setup y Arquitectura Modular:** Refactorización completada mediante interpolación Nix, garantizando escalabilidad para futuros módulos.
- [x] **Maquetación Base (QML):** Diseño *Pill-style* flotante, transparente e interactivo.
- [x] **Módulo Reloj:** Integrado con actualización en tiempo real.
- [x] **Módulo Workspaces (Premium UX):**
  - Renderizado dinámico de píldoras por área de trabajo que cambian de tamaño fluidamente según la cantidad de apps.
  - Generación en tiempo real de los iconos de sistema de las ventanas (usando proveedor nativo `image://icon/` de Qt).
  - Lógica heurística *Custom* para mapear aplicaciones TUI (Yazi, Btop, Neovim) corriendo en terminales (Kitty, etc.) leyendo sus títulos e inyectando su icono original.
  - Evento de clic de cambio de entorno adaptado a la nueva API Lua de llamadas en la comunicación de Quickshell-Hyprland (`hl.dsp.focus`).
- [x] **Módulo Lanzador y Apagado:** Integrados con llamadas por proceso (`Process`).
- [x] **Gestión de Energía Integral:**
  - **Power Profiles:** Selector interactivo y persistente que cambia entre rendimiento, balanceado y ahorro.
  - **Batería Avanzada (Premium UX):** Píldora interactiva que muestra porcentajes e íconos Nerd Font dinámicos (`⚡`, `󰚥`, `🔋`), adaptándose si el límite de carga está topado (80%) y replegando el texto suavemente para ahorrar espacio de pantalla cuando el equipo está conectado.
  - **Popouts Interactivos:** Menús flotantes al hacer clic en módulos (como Batería) con transiciones suaves *fade/slide-up*, cierre haciendo click fuera (`PanelWindow` overlay background), y tarjetas de información contextual (Health, Capacity, Time Remaining, Hardware Limit).

## 🚧 Siguientes Pasos
1. **Módulos de Sistema (CPU/RAM):** Diseñar la lectura interactiva para uso real en los placeholders ya definidos en `system.nix`.
2. **System Tray (Bandeja del sistema):** Añadir el soporte para iconos pasivos (NetworkManager, Bluetooth, Insync) en la parte derecha de la barra.
3. **Control Multimedia (Opcional):** Mostrar información y botones para música usando la API de MPRIS de QuickShell.
