# aduanext_widgetbook

Catálogo de widgets de AduaNext con [Widgetbook](https://pub.dev/packages/widgetbook),
con la misma taxonomía Atomic Design que el widgetbook canónico de altrupets:

```
lib/
  main.dart                  # Widgetbook app + tab Showcase del design system
  use_cases/
    atoms/                   # 7 stories
    molecules/               # 4 stories
    organisms/               # 1 story
  showcase/
    design_system_showcase.dart  # tokens de AduaNextTheme (dark, Ubuntu)
```

Los widgets viven en `apps/mobile/lib/shared/ui/{atoms,molecules,organisms,templates}`
y se referencian por path dependency — no se copian ni se mueven.

## Correr

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

## Cobertura y pendientes

| Nivel     | Con story | Pendientes |
|-----------|-----------|------------|
| atoms     | 7/8       | `LiveIndicator` (ConsumerWidget — requiere ProviderScope + stream de dispatches) |
| molecules | 4/5       | `DuaListItem` (requiere `DispatchDto` de la API) |
| organisms | 1/5       | `DuaTimeline`, `DuaRejectedPanel` (requieren `DispatchDto`), `SidebarPanel`, `SidebarRail` |
| templates | 0/1       | `DashboardLayout` |

Los pendientes comparten causa: dependen de DTOs de la API o de providers de
Riverpod. El paso natural es un builder de fixtures (`DispatchDto` de ejemplo)
compartido entre tests y stories.

## Gap: AduaNext aún no tiene package UI compartido

La UI compartida vive dentro de `apps/mobile/lib/shared/ui/`, no en un package
extraído (estilo `altrupets_ui`). Si se extrae a `libs/` o `packages/`, este
widgetbook solo necesita cambiar la dependency de `aduanext_mobile` al nuevo package.

## Convención

Un archivo por widget: `use_cases/<nivel>/<widget>_use_case.dart`, anotado con
`@widgetbook.UseCase(name: ..., type: ..., path: '[<nivel>]')` y knobs para sus props.
