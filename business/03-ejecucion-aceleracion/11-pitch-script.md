# Guion del Presentador — AduaNext Pitch Deck

> Tiempo total: 8 minutos (pitch) + 4 minutos (Q&A)
> Audiencia: Angeles inversores, fondos pre-seed, aceleradoras LATAM

---

## Slide 1: Portada (15 segundos)

> "Buenas tardes. Soy Andres Pena, fundador de AduaNext.
>
> Imaginen que cada vez que necesitan importar algo — un componente, una materia prima, un equipo — tienen que entregar el control total del proceso a un intermediario que no les explica nada de lo que hace ni por que cobra lo que cobra.
>
> Eso es exactamente lo que le pasa a 3,000 pymes importadoras en Costa Rica. Y vengo a cambiar eso."

**Contacto visual.** Pausa de 2 segundos antes de pasar.

---

## Slide 2: El Problema (45 segundos)

> "Esta cita no la invente yo. Viene del Notion interno de mi empresa, Vertivo, donde documentamos nuestra experiencia importando luces LED desde Shenzhen, China.
>
> *'Los codigos que componen el desglose suelen ser secreto comercial y la agencia aduanal no le explica al comprador.'*
>
> Piensen en eso. El intermediario que se supone que te ayuda a importar, **esconde intencionalmente** como calcula lo que te cobra.
>
> Vertivo paga $1,200 dolares por cada despacho a una agencia. No sabemos que porcentaje es arancel, que es honorario, que es markup. Es una caja negra.
>
> Y esto no es solo Vertivo. En Costa Rica se procesan 2.7 millones de declaraciones aduaneras al ano. Y en octubre del ano pasado, el gobierno lanzo un nuevo sistema aduanero llamado ATENA. Nadie — literalmente nadie — ha construido herramientas que se integren con el."

---

## Slide 3: La Oportunidad (40 segundos)

> "Los numeros hablan solos.
>
> 2.7 millones de DUAs al ano. Tres mil pymes que importan. Doscientas agencias registradas. Y el dato mas importante: **cero competidores integrados con ATENA**.
>
> El mercado total de software aduanero en LATAM es de 320 millones de dolares. Solo Costa Rica y Centroamerica representan 80 millones.
>
> Nosotros apuntamos a capturar 600 mil dolares en revenue anualizado en los primeros 6 meses. Es el 0.75% del mercado servible. Extremadamente conservador.
>
> La ventana de oportunidad es AHORA. ATENA acaba de lanzar, esta lleno de problemas — la Contraloria lo esta auditando — y las agencias estan desesperadas por herramientas."

---

## Slide 4: La Solucion (45 segundos)

> "AduaNext le permite a un importador — una pyme, una startup como Vertivo — preparar su propia declaracion aduanera con transparencia total.
>
> El importador ve cada campo, cada impuesto calculado, cada arancel. Ya no es secreto.
>
> Pero la ley costarricense dice que solo un agente aduanero licenciado puede firmar la declaracion. Entonces lo que hacemos es invertir el modelo: la pyme prepara todo, y contrata a un agente freelance **solo para verificar y firmar**. El agente ya no es el intermediario opaco — es un firmante autorizado.
>
> El resultado: en vez de pagar $1,200 por despacho, la pyme paga $275. Transparente. Controlado. En tiempo real.
>
> Tenemos tres modos de operacion, pero el modelo Importer-Led es nuestra punta de lanza."

---

## Slide 5: Demo — Como Funciona (60 segundos)

> "Dejame mostrarles el flujo concreto con Vertivo importando luces LED desde Shenzhen.
>
> **Paso 1:** Vertivo entra a AduaNext desde un tablet — es Flutter Web, no hay que instalar nada.
>
> **Paso 2:** Crea un borrador de DUA. El sistema busca automaticamente en el catalogo arancelario de ATENA — que tiene mas de 11,000 productos — y sugiere 3 codigos HS con un score de confianza.
>
> **Paso 3:** Antes de enviar, nuestro motor de pre-validacion corre 25 reglas contra la declaracion. Si hay algo sospechoso — un valor CIF muy bajo, una descripcion generica, un HS code que no cuadra — lo marca.
>
> **Paso 4:** Vertivo invita a su agente freelance. El agente recibe la DUA pre-armada, pre-validada. Solo verifica, firma con su certificado digital, y transmite a ATENA. Todo via nuestro sidecar de gRPC.
>
> **Paso 5:** Vertivo recibe un mensaje en Telegram: 'DUA aceptada. Levante autorizado.'
>
> Costo total: $275 dolares. Ahorro del 77% versus la agencia."

**Si hay demo en vivo, mostrar aqui. Si no, el flujo de texto es suficiente.**

---

## Slide 6: Tecnologia (30 segundos)

> "Rapido sobre la tecnologia porque se que hay ingenieros en la sala.
>
> Usamos tres sidecars en un pod de Kubernetes, cada uno en el lenguaje que mejor hace su trabajo: Dart para la API y el ORM, TypeScript para la criptografia y autenticacion con Hacienda, y Python para la clasificacion arancelaria con inteligencia artificial.
>
> Tenemos documentadas las 6 APIs de declaraciones y los 40 endpoints del catalogo arancelario de ATENA. Nadie mas tiene esto.
>
> Y lo mas importante: nuestro domain layer tiene cero dependencias de I/O. Cuando agreguemos Guatemala o Mexico, solo creamos nuevos adaptadores. Cero cambios al core."

---

## Slide 7: Modelo de Negocio (40 segundos)

> "Revenue viene de tres fuentes.
>
> Primero, suscripcion mensual de las pymes: $120 al mes en plan estandar, con un early adopter rate de $60 permanente para los primeros 50 clientes.
>
> Segundo, transaccional: $5 por cada DUA procesada. Esto alinea nuestro revenue con el volumen de operaciones del cliente.
>
> Tercero, revenue share con los agentes freelance: cobramos $20 al mes de base mas el 10% de lo que el agente cobra por firma. Esto alinea incentivos — nosotros ganamos mas solo si el agente gana mas.
>
> Y a futuro, tenemos licencias universitarias a $800 al mes y un tier premium para exportadores grandes."

---

## Slide 8: Unit Economics (30 segundos)

> "Estos son los numeros que realmente importan.
>
> Costo de adquisicion: $116 dolares, principalmente content marketing y referidos — que son gratuitos.
>
> Valor de vida del cliente: $2,171. Eso es un ratio LTV sobre CAC de casi 19 a 1. El benchmark de SaaS saludable es 3 a 1.
>
> Payback en menos de un mes. Margen bruto del 87%.
>
> Y el dato que mas me gusta: nuestro burn rate pre-revenue es de $302 dolares al mes. Trescientos dos dolares. Eso es hosting mas Claude Code. No hay salarios, no hay oficina, no hay ventas outbound. Breakeven en el mes 4."

---

## Slide 9: Traccion y Roadmap (40 segundos)

> "No somos solo una idea. Ya tenemos el spike tecnico completo: la arquitectura, los schemas de datos que hacen match exacto con la API de ATENA, las definiciones de gRPC, y el domain layer implementado en Dart.
>
> El proximo paso es el sidecar de autenticacion — arranca esta semana. En mayo tenemos los adaptadores de ATENA. En junio hacemos la beta real: Vertivo importa luces LED desde Shenzhen usando AduaNext con un agente freelance. Primera DUA real transmitida a ATENA.
>
> Julio es el lanzamiento de early adopters. Apuntamos a 50 pymes.
>
> Y en paralelo, estamos negociando un convenio con la UCR o la UTN para el sandbox educativo. Esto es el flywheel..."

---

## Slide 10: Growth Flywheel (45 segundos)

> "...y este es el flywheel que hace que AduaNext sea practicamente imposible de copiar.
>
> Costa Rica tiene 8 universidades con 18 programas de administracion aduanera. Dos mil estudiantes al ano. Hoy aprenden con screenshots de un sistema que ya no existe — TICA fue reemplazado por ATENA.
>
> Nosotros les damos AduaNext gratis como sandbox educativo. Los estudiantes aprenden con el sistema real. Al graduarse y pasar el examen de la DGA, ya saben usar AduaNext. Se registran como agentes freelance. Atienden a pymes que usan AduaNext. Las pymes refieren a otras pymes. Mas demanda de agentes. Las universidades capacitan mas.
>
> Es el modelo Autodesk: gratis para estudiantes, pago al graduarse. Pero con un twist — el estudiante convierte en SUPPLY side del marketplace, no solo en cliente.
>
> Esto toma 2-3 anos en construir. Nadie puede replicarlo rapido. Es nuestro moat."

---

## Slide 11: Competencia (30 segundos)

> "Los competidores mas cercanos estan en Mexico: AduanApp y Aduanasoft.
>
> AduanApp es un clasificador con AI — como un ChatGPT aduanero. Cobra por tokens. Pero no genera pedimentos, no transmite a ningun sistema de gobierno, no tiene marketplace de agentes.
>
> Aduanasoft es un software de escritorio de 1996. Windows. SQL Server. Treinta anos de deuda tecnica.
>
> Ninguno opera en Centroamerica. Ninguno se integra con ATENA.
>
> La diferencia fundamental: ellos son asesores — te dicen que codigo usar. Nosotros somos operadores — preparamos, firmamos, transmitimos y monitoreamos la declaracion completa."

---

## Slide 12: El Equipo (30 segundos)

> "Soy Andres Pena. Arquitecto de software con experiencia en Kubernetes, microservicios y sistemas distribuidos.
>
> Soy tambien fundador de Vertivo LATAM — una startup de micro-invernaderos autonomos. Vertivo necesita importar componentes. Ese dolor real es lo que me llevo a construir AduaNext.
>
> Soy el autor del SDK hacienda-cr — la unica libreria open-source que implementa autenticacion y firma digital para Hacienda de Costa Rica. Nadie mas tiene esto.
>
> Y mi co-developer es Claude Code — un modelo de AI que me permite hacer en 1 dia lo que un equipo de 3 personas haria en 2 semanas. Toda la arquitectura, los spikes, y el modelo de negocio que ven aqui se produjeron en una sola sesion."

---

## Slide 13: El Ask (30 segundos)

> "Hoy no les estoy pidiendo plata.
>
> Nuestro burn rate es $302 al mes. Vertivo financia la operacion. Vamos a llegar a la beta sin capital externo.
>
> Lo que si necesitamos en el mes 8 — cuando tengamos $10K de MRR validado y 50 clientes activos — es un pre-seed de $100 mil dolares. El 60% va a equipo: un customer success que venga del mundo aduanero y un desarrollador Flutter. El 20% a marketing. El resto a infraestructura y legal.
>
> Lo que les pido hoy es: si conocen pymes que importan, si conocen agentes aduaneros jovenes que quieran emprender, o si conocen coordinadores de carrera en universidades — conectenme. Esas tres conexiones valen mas que dinero en esta etapa."

---

## Slide 14: Contacto (15 segundos)

> "AduaNext. Tu importacion, tu control.
>
> Mi correo es andres@vertivolatam.com. Estoy en LinkedIn como lapc506.
>
> Gracias."

**Pausa. Esperar aplausos/silencio. Abrir Q&A.**

---

## Preguntas Frecuentes (Q&A Prep)

### "No es ilegal que una pyme prepare su propia DUA?"

> "No. La ley 7557 dice que un agente aduanero debe FIRMAR la DUA. No dice quien la PREPARA. La pyme prepara, el agente verifica y firma. Es como que vos preparas tu declaracion de renta y un contador la firma. Legal, eficiente, transparente."

### "Que pasa si ATENA cambia su API?"

> "Nuestra arquitectura hexagonal tiene un Adapter pattern. ATENA es una implementacion detras de un puerto abstracto. Si cambia la API, solo cambia el adaptador. Cero cambios al core. De hecho, ya estamos preparados para agregar Guatemala y Mexico con el mismo patron."

### "Como consiguen los agentes freelance?"

> "Tres canales: LinkedIn y el Colegio de Ciencias Economicas para los primeros 5. Despues, el convenio universitario. Cada agosto, la DGA aplica el examen para nuevos agentes. Los graduados que practicaron con AduaNext en la universidad ya saben usarlo. Se registran como freelance desde el dia 1."

### "Por que no levantan capital ahora?"

> "Porque no lo necesitamos. Nuestro burn es $302 al mes. Levantar capital antes de validar product-market fit diluiria sin razon. Cuando tengamos 50 clientes pagando y una importacion real exitosa, el capital va a multiplicar algo que ya funciona — no a financiar incertidumbre."

### "Que tan grande puede ser esto?"

> "Costa Rica es el punto de entrada. Centroamerica tiene 6 paises con sistemas aduaneros compatibles via CAUCA. Mexico es un mercado de $160 millones donde el software incumbente tiene 30 anos. Y cada pais al que entremos, solo necesita nuevos adaptadores — el core es el mismo. A 3 anos, estamos apuntando a $5M ARR con presencia en 4 paises."

### "AduanApp en Mexico no es competencia?"

> "AduanApp es un clasificador — te dice que codigo HS usar. Nosotros hacemos eso Y ADEMAS preparamos la declaracion, la firmamos con certificado digital, la transmitimos al gobierno, y monitoreamos el estado. Es como comparar Google Maps (te dice a donde ir) con Uber (te lleva). Nosotros somos Uber."
