# Instrucciones para Agentes de IA - Proyecto GTA

**Idioma**: Todos los agentes deben comunicarse exclusivamente en **español**.

## 📋 Descripción del Proyecto

**GTA** - Gestión de Turnos y Asistencia es una aplicación Flutter multiplataforma (Android, iOS, Web) que gestiona turnos de empleados y asistencia con validación mediante código QR y geolocalización.

- **Arquitectura**: MVVM (Model-View-ViewModel)
- **Backend**: Supabase (autenticación + base de datos)
- **Versión Mínima**: Flutter 3.11.1, Dart 3.11.1

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart              # Entry point con AuthWrapper
├── config/                # SupabaseConfig (singleton centralizado)
├── models/                # Entidades de datos
├── viewmodels/            # Lógica de negocio (BaseViewModel + derivados)
├── views/                 # UI organizadas por roles (auth/, empleado/, gerente/)
├── services/              # 7 servicios especializados (Supabase, Horarios, QR, etc.)
├── widgets/               # ViewModelBuilder (patrón personalizado MVVM)
└── utils/                 # Constantes, colores, helpers
```

## 🎯 Patrones Arquitectónicos

### 1. **MVVM Personalizado**

- **BaseViewModel**: Clase base que extiende `ChangeNotifier`
  - Proporciona `runSafe<T>()` para operaciones async con manejo automático de loading/error
  - Implementa ciclo de vida con `dispose()`

- **ViewModelBuilder**: Widget genérico personalizado (ubicado en `widgets/`)
  - Instancia, provee y reconstruye ViewModels automáticamente
  - Maneja disposal automático si es necesario
  - Implementa Provider pattern personalizado

- **Consumer**: Accede al ViewModel más cercano sin pasar parámetros manualmente

### 2. **Estructura de ViewModels**

Cada ViewModel maneja lógica de un flujo específico:

```dart
class MiViewModel extends BaseViewModel {
  // Estado privado
  String _dato = '';
  
  // Getter público
  String get dato => _dato;
  
  // Método con runSafe para automatizar loading/error
  Future<void> cargarDatos() async {
    await runSafe(() async {
      _dato = await miService.obtenerDatos();
      notifyListeners();
    });
  }
}
```

### 3. **Separación por Roles**

Las vistas están organizadas por flujos de usuario:
- `views/auth/` - Login/Register
- `views/empleado/` - Funcionalidades para empleados
- `views/gerente/` - Funcionalidades para gerentes

## 📝 Convenciones de Código

### Nomenclatura

| Elemento | Regla | Ejemplo |
|----------|-------|---------|
| **Variables privadas** | `_nombreVariable` | `_empleados`, `_cargando` |
| **Variables de Supabase** | `snake_case` | `fecha_entrada`, `salario_por_hora` |
| **Getters públicos** | `camelCase` | `empleados`, `cargando` |
| **Métodos** | `verboCamelCase()` | `cargarEmpleados()`, `marcarEntrada()` |
| **Clases** | `PascalCase` descriptiva | `EmpleadoViewModel`, `HorarioService` |
| **Archivos** | `snake_case.dart` | `empleado_viewmodel.dart` |

### Comentarios en Español

Todos los comentarios deben estar en **español**, incluyendo:
- Documentación de clases y métodos
- Explicaciones de lógica compleja
- TODOs y FIXMEs

## ⚡ Comandos Frecuentes

```powershell
# Desarrollo
flutter run                    # Ejecutar en dispositivo conectado
flutter run -d web             # Ejecutar en navegador
flutter run --profile          # Ejecutar con profiling
flutter pub get                # Descargar dependencias

# Build
flutter build apk              # Generar APK (Android)
flutter build ios              # Generar para iOS
flutter build web              # Generar para Web

# Análisis
flutter analyze                # Verificar lints según analysis_options.yaml
dart format lib/               # Formatear código
```

## 🔑 Librerías Principales

| Librería | Propósito |
|----------|-----------|
| `supabase_flutter` | Backend (autenticación + base de datos) |
| `qr_flutter`, `mobile_scanner` | Generación y lectura de códigos QR |
| `geolocator` | Validación de ubicación geográfica |
| `shared_preferences` | Almacenamiento local |
| `flutter_local_notifications` | Notificaciones locales |
| `intl` | Internacionalización y formato de fechas |

## 📌 Patrones Personalizados del Proyecto

### ViewModelBuilder

```dart
// Instancia automáticamente el ViewModel y lo provee
ViewModelBuilder<MiViewModel>(
  viewModelBuilder: () => MiViewModel(),
  builder: (context, viewModel) {
    return MiVista(viewModel: viewModel);
  },
);
```

### SupabaseConfig

Singleton centralizado para acceso a cliente Supabase:
```dart
final supabase = SupabaseConfig.instance.client;
final constants = SupabaseConfig.instance.constants;
```

### runSafe() en ViewModels

Automatiza loading, errores y notificación de cambios:
```dart
await runSafe(() async {
  // Tu lógica async aquí
});
```

## 🚀 Cuando Trabajes en Este Proyecto

1. **Comunica exclusivamente en español** - En documentación, comentarios y conversación
2. **Respeta MVVM** - Lógica en ViewModels, UI en Views
3. **Usa ViewModelBuilder** - No uses Provider directamente
4. **Implementa runSafe()** - Para todas las operaciones async en ViewModels
5. **Organiza por roles** - Agrupa views relacionadas en carpetas de roles/features
6. **Ejecuta análisis** - `flutter analyze` debe pasar sin errores
7. **Consulta archivos de configuración** - [analysis_options.yaml](analysis_options.yaml) para lints
8. **Valida en Supabase** - Las reglas de negocio críticas deben validarse en la base de datos

## 📚 Archivos Clave

- [pubspec.yaml](pubspec.yaml) - Dependencias del proyecto
- [lib/viewmodels/base_viewmodel.dart](lib/viewmodels/base_viewmodel.dart) - Clase base para ViewModels
- [lib/widgets/viewmodel_builder.dart](lib/widgets/viewmodel_builder.dart) - Widget personalizado MVVM
- [lib/config/supabase_config.dart](lib/config/supabase_config.dart) - Configuración centralizada
- [analysis_options.yaml](analysis_options.yaml) - Reglas de análisis de código

---

**Última actualización**: 2026-04-28
