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
  - `misc.nix`: Isla miscelánea que aloja el selector dinámico de *Power Profiles*, el botón de sesión interactuando con subprocesos del sistema (`powerprofilesctl`), y el módulo interactivo MPRIS. Aquí iremos implementando más widgets en el futuro.
  - `system.nix`: Botón lanzador de aplicaciones (`walker`) y *placeholders* visuales de CPU y RAM.
  - `workspaces.nix`: Integración nativa bidireccional con Hyprland (`Quickshell.Hyprland`). Identifica dinámicamente las ventanas abiertas en cada escritorio renderizando su icono del sistema y agrupándolas inteligentemente mediante una heurística de *class* y *título*.
## 🚀 Progreso Actual
- [x] **Setup y Arquitectura Modular:** Refactorización completada mediante interpolación Nix, garantizando escalabilidad para futuros módulos.
- [x] **Maquetación Base (QML):** Diseño *Pill-style* flotante, transparente e interactivo.
- [x] **Módulo Reloj y Calendario (Premium UX):**
  - Reloj central en la barra con actualización en tiempo real.
  - Al hacer click abre un popup interactivo o "isla" dividido en dos paneles.
  - Integración del motor de calendario y *Memento Mori* (esperanza de vida) porteado desde Omarchy (`Model.js`).
  - Navegación interactiva por meses con *hover effects* en el título del mes ("BACK TO TODAY").
  - Gestión correcta del teclado en Wayland (`HyprlandFocusGrab` y `WlrLayershell.keyboardFocus`) para la inserción del año.
- [x] **Módulo de Notificaciones (Premium UX Completado):**
  - Integración robusta de la API de notificaciones nativa de Quickshell.
  - Historial de notificaciones agrupado por aplicaciones dentro de la isla del reloj.
  - Funciones asíncronas seguras para limpiar (`Clear All`), descartar grupos y descartar individualmente.
  - Popups OSD flotantes dinámicos (ListView) con transiciones suaves en tiempo real.
  - Soporte integral para iconos (Avatares en OSD, Iconos de App en grupos) con lógica de fallback automático.
  - Interactividad total soportando acciones (`actions`) nativas para abrir apps al clickar.
  - Strip de etiquetas HTML embebidas y control avanzado de tipografía.
- [x] **Módulo Multimedia (Completado):**
  - Reproductor interactivo en la isla (mediante MPRIS).
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
- [x] **Módulo System Monitor (CPU/RAM):**
  - Popout interactivo con alineación a la izquierda y dimensionamiento (`implicitWidth`/`implicitHeight`) optimizado.
  - Generación de gráficos circulares dinámicos (QML `Canvas`) para el uso global del sistema.
  - Listas de los 5 procesos principales que más consumen integradas nativamente sin bloqueos.
  - UX de hover en filas con iconos de borrado dinámicos para fulminar procesos (`kill`).
  - Botón integrado para lanzar Btop completo.
- [x] **Módulo System Tray:**
  - Integración nativa con `Quickshell.Services.SystemTray`.
  - Soporte para iconos pasivos (NetworkManager, Bluetooth, Insync) y renderizado adaptativo de los iconos desde el path o tema local.
  - Interacciones de ratón nativas (Left/Right/Middle clicks) conectadas a los métodos del provider del Tray.



## 🚧 Siguientes Pasos
1. **Control Multimedia (Opcional):** Mostrar información y botones para música usando la API de MPRIS de QuickShell.

## 🎨 UI/UX Guidelines & Consistency
Para mantener la homogeneidad visual ("Premium UX") en todos los componentes de Quickshell, se deben seguir estrictamente las siguientes reglas de diseño:
- **Títulos de Popups:** Deben usar `font.pixelSize: 18` sin estar en negrita (`font.bold: false` u omitido).
- **Subtítulos (Pills/Sections):** Los textos descriptivos sobre tarjetas (ej. "Top CPU", "Health", "Capacity") deben heredar el color Cyan de Stylix (`#${c.base0D}`) y tener un `font.pixelSize: 13` centrado horizontalmente (`Layout.alignment: Qt.AlignHCenter`).
- **Botones Interactivos:** Los botones grandes de la parte inferior de los menús (ej. cambiar perfil de energía, lanzar aplicaciones) deben usar un formato "pill-style" redondeado (`radius: 20`) sin borde. El color de fondo en reposo será el oscuro estándar de los menús (`#${c.base02}`), y al hacer hover cambiará a un gris claro sutil (`#${c.base03}`). Su texto no debe estar en negrita a menos que representen un estado activo.
- **Listas y Filas:** En lugar de forzar clics precisos en botones diminutos, las filas de las listas deben estar envueltas en rectángulos clickables (`MouseArea` sobre toda la fila) con un ligero resalte en hover (`#${c.base03}`). Los iconos de acción (ej. papelera de reciclaje) sólo serán visibles (`visible: mouseArea.containsMouse`) cuando se pase el ratón por encima de la fila.
- **Fondo de las Islas (Pills):** Todos los widgets principales de la barra superior que funcionen como "islas" independientes (Reloj, Monitor del Sistema, System Tray, Batería, etc.) deben tener por defecto un color de fondo unificado de `#${c.base01}`. Al pasar el ratón (hover), el fondo debe cambiar a `#${c.base03}`, y cuando su menú esté activo/abierto, el botón debe adoptar el color `#${c.base02}`.
- **Alineación de Popups:** Para que un menú flotante o popup aparezca perfectamente centrado debajo de la isla que lo lanza, NO se deben usar coordenadas absolutas o rectángulos quemados en código. Se debe referenciar a la isla mediante `anchor.item`, declarando únicamente `anchor.edges: Edges.Bottom` y `anchor.gravity: Edges.Bottom`. Quickshell aplicará automáticamente el centrado horizontal por omisión de los bordes laterales.

## 📚 Referencias y Documentación
- **Documentación Oficial de Quickshell (v0.1.0):** [https://quickshell.org/docs/v0.1.0/guide/](https://quickshell.org/docs/v0.1.0/guide/)
- **Proyectos de Referencia Local (Código Fuente):**
  - **DankMaterialShell (DMS):** `/home/egarcia/Development/git/DankMaterialShell`
  - **Omarchy:** `/home/egarcia/Development/git/omarchy`
  - *(Nota para el agente: Cuando se solicite revisar o copiar funcionalidades de estos proyectos, se debe investigar a fondo el código fuente en estos directorios).*
