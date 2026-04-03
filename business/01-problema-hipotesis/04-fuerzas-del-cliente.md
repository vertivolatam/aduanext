# Fuerzas del Cliente — Modelo Importer-Led

## Diagrama de Fuerzas (Customer Forces Canvas)

```
    PUSH (dolor actual)              PULL (solucion deseada)
    ─────────────────                ────────────────────────
    "Pago $1,200/despacho           "Pagar <$500 con
     y no se por que"                transparencia total"

    "La agencia es una              "Preparar yo mismo la DUA
     caja negra"                     y que el agente solo firme"

    "No se cuando llega             "Monitorear en tiempo real
     mi carga"                       desde mi celular"

    "ATENA es nuevo y nadie         "Una plataforma que ya
     sabe usarlo bien"               este integrada con ATENA"

           ↓                               ↓
    ═══════════════════════════════════════════════
    ←  ANXIETY (miedos)        HABITS (inercia)  →
    ═══════════════════════════════════════════════
           ↑                               ↑

    "Si la DUA se rechaza,          "Mi agencia actual me
     pierdo la mercaderia"           conoce y responde rapido"

    "No conozco agentes             "Ya tengo el proceso
     freelance confiables"           funcionando, aunque caro"

    "Que pasa si AduaNext           "Cambiar es riesgoso,
     desaparece?"                    una DUA mal hecha me
                                     cuesta $20K de caucion"

    "No soy experto en              "El agente actual me
     clasificacion arancelaria"      resuelve todo, sin preguntas"
```

## Analisis de Fuerzas

### Fuerzas PUSH (empujan al cliente a buscar alternativa)

| Fuerza | Intensidad | Frecuencia |
|--------|-----------|------------|
| Costo excesivo vs. valor percibido | ALTA | Cada despacho (4-12x/ano) |
| Opacidad total del proceso | ALTA | Permanente |
| Sin visibilidad real-time | MEDIA | Cada despacho |
| Transicion ATENA sin soporte | ALTA | Ahora (2025-2026) |
| Dependencia de una sola agencia | MEDIA | Cuando hay problemas |

### Fuerzas PULL (atraen al cliente hacia AduaNext)

| Fuerza | Intensidad | Diferenciador? |
|--------|-----------|----------------|
| Ahorro >60% por despacho | ALTA | Si — ningun competidor ofrece esto |
| Transparencia total de costos | ALTA | Si — las agencias lo consideran "secreto" |
| Monitoreo real-time (Telegram) | MEDIA | Parcial — algunas agencias lo hacen manual |
| Integracion ATENA nativa | ALTA | Si — nadie mas esta integrado |
| Elegir tu propio agente freelance | MEDIA | Si — modelo de mercado nuevo |

### Fuerzas ANXIETY (frenan la adopcion)

| Miedo | Severidad | Mitigacion en AduaNext |
|-------|-----------|----------------------|
| DUA rechazada = perdida de mercaderia | ALTA | Risk pre-validation (25 reglas) antes de enviar |
| No encontrar agente freelance confiable | MEDIA | Trust score + reviews + matching automatico |
| AduaNext desaparece (startup risk) | MEDIA | Open-source (BSL 1.1), datos exportables |
| Error de clasificacion arancelaria | ALTA | AI-assisted + RIMM validation + human-in-the-loop |
| Complejidad tecnica de ATENA | MEDIA | UX simplificada para importadores, no para agentes |

### Fuerzas HABIT (mantienen al cliente con la agencia actual)

| Habito | Intensidad | Como romperlo |
|--------|-----------|---------------|
| "Mi agencia me conoce" | MEDIA | El agente freelance en AduaNext tambien "te conoce" — historial completo |
| "Ya funciona, aunque caro" | ALTA | Mostrar ahorro acumulado en 1 ano: $7,200 → $2,400 ($4,800 ahorrados) |
| "Cambiar es riesgoso" | ALTA | Primera importacion en sandbox (riesgo cero), luego produccion |
| "No quiero aprender otro sistema" | MEDIA | Onboarding <5 min + UX para no-expertos |

## Trigger Events (momentos de cambio)

Cuando es mas probable que una pyme busque alternativa:

1. **Factura de la agencia inesperadamente alta** — "Me cobraron el doble este mes"
2. **Error de la agencia** — "Clasificaron mal y tuve que pagar multa"
3. **Agente se va de la agencia** — "Mi agente de confianza se fue y el nuevo no me conoce"
4. **Primera importacion de la startup** — No tiene agencia, busca opciones desde cero
5. **ATENA lanza nueva funcionalidad** — La agencia actual no se ha actualizado
6. **Referido de otra startup** — "En Vertivo usan AduaNext y les sale 60% mas barato"

**Trigger mas poderoso:** Referido de peer (startup → startup). Es el canal #1 del modelo Importer-Led.
