# **ADUANEXT: MEGA-PROMPT PARA SPIKE TÉCNICO Y REQUERIMIENTOS**

## **1\. IDENTIDAD Y ROL**

Eres un arquitecto de software senior especializado en sistemas agenticos y cumplimiento aduanero internacional. Tu misión es actuar como el núcleo de un agente tipo **OpenClaw/Hermes** que interactuará con el Sistema Integrado de Administración Aduanera de Costa Rica (**ATENA**) y sistemas regionales de Centroamérica.

## **2\. CONTEXTO TÉCNICO (COSTA RICA 2026\)**

* **Plataforma Core:** ATENA (reemplazo de TICA) basado en arquitectura de microservicios y APIs RESTful.  
* **Formato de Datos:** Mensajería estricta en **JSON** siguiendo el **Modelo de Datos de la OMA v4.1**.  
* **Autenticación:** Protocolo **OpenID Connect** con tokens de acceso JWT y uso obligatorio de **Firma Digital**.  
* **Fiscalización:** Integración con **TRIBU-CR** para validación de facturas electrónicas y declaraciones informativas mensuales (D-270).

## **3\. OBJETIVOS DEL SPIKE (TASK LIST)**

Para este spike, debes analizar y estructurar lo siguiente:

1. **Mapeo de Datos:** Traducir los campos de una factura comercial estándar al esquema JSON del **DUA de Exportación** definido en la Guía Técnica de ATENA.  
2. **Lógica de Clasificación:** Diseñar un flujo que consulte el módulo **RIMM (Gestión de Información de Referencia)** para validar partidas arancelarias y notas técnicas.  
3. **Gestión de Estados:** Mapear el ciclo de vida de la declaración (Almacenamiento \-\> Validación \-\> Liquidación \-\> Levante) y definir "triggers" de notificación vía Telegram/WhatsApp.

## **4\. DEFINICIÓN DE "SKILLS" ADUANERAS (LÓGICA HERMES/NEMOCLAW)**

Instruye al runtime del agente para desarrollar las siguientes capacidades:

* **Skill `atena_auth`:** Lógica para refrescar tokens OpenID y manejar el handshake con el gateway de Firma Digital local.  
* **Skill `rimm_query`:** Capacidad de búsqueda avanzada en catálogos arancelarios usando filtros de descripción comercial.  
* **Skill `cross_border_sync`:** Implementar el mapeo para la **DUCA-F** y **DUCA-T** a través de la Plataforma Digital de Comercio Centroamericana (PDCC) para operaciones multinacionales.

## **5\. REQUERIMIENTOS DE CUMPLIMIENTO Y SEGURIDAD**

* **Bitácora de Auditoría:** Generar un registro inalterable en Markdown de cada decisión de clasificación y transmisión para fiscalización a posteriori.  
* **Sandbox de Transmisión:** Ejecutar todas las llamadas de API en un entorno Docker aislado para evitar el compromiso de la caución aduanera ($20.000 USD) ante errores críticos.  
* **Validación de Riesgo:** Implementar un paso previo de "Gestión de Riesgo Inteligente" antes de la validación oficial de ATENA para detectar discrepancias en valores CIF o descripciones genéricas.

## **6\. INSTRUCCIONES DE SALIDA (SPIKE OUTPUT)**

Al finalizar el spike, genera un reporte técnico que contenga:

1. Un diagrama de secuencia de la interacción: Agente \<-\> Gateway Local \<-\> API ATENA.  
2. Un ejemplo de payload JSON para un DUA de exportación validado.  
3. Una lista de brechas detectadas en la documentación técnica actual de Hacienda Digital respecto a la interoperabilidad multinacional.

---

### **Notas para el uso de NemoClaw o Hermes-Agent:**

* **Local-First:** Este prompt asume que el agente tiene acceso a archivos locales para lectura de PDFs técnicos proporcionados.  
* **Persistent Memory:** El agente debe usar su base de datos de memoria (FTS5 en Hermes) para recordar las correcciones de clasificación arancelaria que el usuario realice manualmente en el spike.  
* **Identity (SOUL.md):** Si usas Hermes, integra esta identidad en el archivo `SOUL.md` para asegurar que el tono sea siempre profesional, preciso y centrado en la reducción de riesgos fiscales.

Referencias:

* [https://www.hacienda.go.cr/docs/SIAA-ATENA-DUA-GUIA-TECNICA.pdf](https://www.hacienda.go.cr/docs/SIAA-ATENA-DUA-GUIA-TECNICA.pdf)  
* [https://hermes-agent.nousresearch.com/docs/](https://hermes-agent.nousresearch.com/docs/)  
* [https://docs.nvidia.com/nemoclaw/latest/index.html](https://docs.nvidia.com/nemoclaw/latest/index.html)  
* 

# **Análisis estratégico y guía integral para el establecimiento de agencias de aduanas en Costa Rica: Marco regulatorio, transformación digital y operatividad en el horizonte de 2026**

El establecimiento de una agencia de aduanas en el territorio costarricense representa una de las iniciativas empresariales de mayor complejidad técnica y responsabilidad legal dentro del sector de servicios logísticos. En el contexto actual de marzo de 2026, este proceso no solo demanda un conocimiento profundo de la Ley General de Aduanas (Ley 7557\) y sus reglamentos, sino también una adaptación inmediata a la transformación estructural que ha experimentado el Ministerio de Hacienda a través del proyecto Hacienda Digital.1 La transición de los sistemas tradicionales hacia plataformas unificadas como TRIBU-CR y ATENA ha redefinido la interacción entre el Estado y los auxiliares de la función pública aduanera, exigiendo que cualquier nuevo emprendedor en este ramo posea una visión integral que combine la pericia jurídica, la solvencia financiera y una infraestructura tecnológica de vanguardia.2

## **El ecosistema del Sistema Aduanero Nacional y la jerarquía normativa**

Para comprender el funcionamiento de una agencia de aduanas, es imperativo analizar primero el Sistema Aduanero Nacional (SAN). Según el Artículo 7 de la Ley General de Aduanas, el SAN está constituido por el Servicio Nacional de Aduanas y las entidades, tanto públicas como privadas, que ejercen gestión aduanera bajo el régimen jurídico correspondiente.1 La agencia de aduanas se posiciona dentro de este sistema como un auxiliar de la función pública, lo que le otorga una naturaleza dual: es una entidad privada con fines de lucro, pero actúa bajo la delegación del Estado para facilitar el comercio exterior y asegurar la correcta percepción de los tributos.5

La operatividad de estas entidades se rige por una jerarquía normativa estricta. De acuerdo con el Artículo 4 de la Ley 7557, las fuentes del régimen jurídico aduanero se sujetan a un orden específico que comienza con la Constitución Política, seguida de los tratados internacionales y las normas de la comunidad centroamericana (como el CAUCA y el RECAUCA), las leyes nacionales y, finalmente, los reglamentos y disposiciones administrativas.5 Esta estructura asegura que la actuación del agente aduanero esté siempre alineada con los compromisos internacionales de facilitación del comercio y simplificación aduanera, tales como el Convenio de Kyoto Revisado, cuya entrada en vigencia en Costa Rica ha marcado un hito en la modernización de los controles.8

El Servicio Nacional de Aduanas, como órgano de control del comercio exterior y de la Administración Tributaria, depende directamente del Ministerio de Hacienda.7 Su dirección recae en una Dirección General y una Subdirección que deben estar lideradas por profesionales con grado de licenciatura y amplia experiencia en el ramo.1 Para el fundador de una agencia, esta estructura jerárquica implica que toda su gestión estará bajo la fiscalización de diversas aduanas técnicas-administrativas, las cuales tienen competencia territorial o funcional sobre las entradas, permanencias y salidas de mercancías.1

### **Estructura funcional de las Aduanas en Costa Rica**

| Unidad / Departamento | Funciones Principales en el Marco de 2026 |
| :---- | :---- |
| Gerencia de Aduana | Organizar, dirigir y controlar las operaciones aduaneras en su jurisdicción conforme a las políticas del Sistema.9 |
| Departamento Técnico | Aplicar exenciones tributarias, coordinar con otras autoridades gubernamentales y ejecutar gestiones de control técnico.1 |
| Departamento de Agentes Externos | Supervisar la actuación de los auxiliares de la función pública y gestionar los registros de personal acreditado.9 |
| División de Control y Fiscalización | Intervenir en investigaciones de defraudación fiscal y coordinar auditorías a posteriori sobre las operaciones despachadas.9 |
| Puestos de Control Fronterizo | Vigilancia de unidades de transporte y mercancías en carreteras, vías marítimas o fluviales, aplicando políticas de "cero papel".8 |

## **La figura del Auxiliar de la Función Pública Aduanera**

El concepto de auxiliar es piedra angular para quien desea fundar una agencia. Según el Artículo 28 de la Ley General de Aduanas, se consideran auxiliares las personas físicas o jurídicas que habitualmente efectúan operaciones aduaneras en nombre propio o de terceros.5 Esta definición conlleva una carga de responsabilidad solidaria ante el fisco por las consecuencias tributarias derivadas de los actos u omisiones de sus empleados.1 El agente aduanero, en particular, es el representante legal de su mandante para todas las actuaciones y notificaciones del despacho aduanero, asumiendo una responsabilidad civil ante su cliente por cualquier lesión patrimonial que surja de su mandato.1

### **Obligaciones y prohibiciones fundamentales**

La normativa impone obligaciones básicas a los auxiliares que deben ser contempladas en el plan de negocios inicial. Estas incluyen llevar registros detallados de todas las actuaciones ante el Servicio Nacional de Aduanas, mantener oficinas abiertas en las jurisdicciones donde prestan servicios y estar integrados en los sistemas informáticos autorizados.1 En 2026, esta integración tecnológica se ha vuelto más exigente con la obligatoriedad de utilizar firmas digitales y mantener expedientes electrónicos interoperables con las autoridades.3

Existen impedimentos legales claros para ejercer como auxiliar. No pueden optar por esta condición los funcionarios del Estado o de instituciones autónomas, ni las personas inhabilitadas por sentencia judicial firme para ejercer cargos públicos.1 Asimismo, los agentes aduaneros tienen prohibido sustituir el mandato que se les ha conferido o transferir derechos correspondientes a sus mandantes, aunque el mandante sí puede sustituir al agente en cualquier momento mediante comunicación escrita.1

## **Requisitos de idoneidad profesional para Agentes Aduaneros**

Si el fundador desea actuar como agente aduanero persona física o designar a uno para su agencia jurídica, debe cumplir con un perfil académico y profesional riguroso. La Ley exige el grado de licenciatura en Administración Aduanera, Comercio Exterior, Derecho o Administración Pública.1 Específicamente, instituciones como la Universidad Técnica Nacional (UTN) ofrecen planes de estudio que abarcan desde el diplomado hasta la licenciatura, diseñados para formar el recurso humano competitivo que demanda el sector.14

Además de la titulación, el aspirante debe demostrar una experiencia mínima de dos años en materia aduanera, acreditada mediante declaración jurada ante notario público.13 Un requisito crítico es la aprobación de un examen de competencia aplicado anualmente por la Dirección General de Aduanas, usualmente en el mes de agosto.13 Este examen evalúa conocimientos en merceología, valoración aduanera y normativa procedimental.15

### **Incorporación al Colegio de Profesionales en Ciencias Económicas**

La colegiación es obligatoria para el ejercicio legal de la profesión en Costa Rica. Para marzo de 2026, el proceso de incorporación se realiza mayoritariamente en línea e implica varios requisitos y costos asociados que deben ser presupuestados.16

| Concepto de Trámite | Requisito / Detalle | Costo / Periodicidad (2026) |
| :---- | :---- | :---- |
| Derechos de Incorporación | Título universitario certificado, antecedentes penales y fotografía pasaporte.16 | ¢45.000 a ¢65.600 colones.16 |
| Cuota Mensual Ordinaria | Pago obligatorio para mantenerse como miembro activo y habilitado.16 | ¢8.300 colones.16 |
| Curso de Inducción | Participación virtual obligatoria en talleres de ética y normativa gremial.16 | Incluido en trámites iniciales.16 |
| Juramentación | Sesiones mensuales programadas según cronograma anual del Colegio.16 | Requisito final de habilitación.16 |

## **Constitución de la Agencia de Aduanas como Persona Jurídica**

La mayoría de los emprendedores optan por la figura de persona jurídica debido a las ventajas en gestión de marca y limitación de riesgos patrimoniales personales, aunque la responsabilidad ante el fisco siga siendo solidaria. Para ser autorizada, la sociedad debe estar constituida y domiciliada en Costa Rica, con un objeto social que prevea expresamente el ejercicio de la correduría aduanera.10

### **El proceso de autorización paso a paso**

El trámite se inicia con la presentación del formulario DER01 ante el Ministerio de Hacienda, el cual debe estar firmado por el representante legal y autenticado por un notario.4 La documentación requerida incluye la personería jurídica actualizada, certificaciones notariales de domicilio y la ubicación exacta de las oficinas en cada jurisdicción aduanera donde operará la agencia.4

Una vez que el Ministerio verifica el cumplimiento de los requisitos, se emite un Acuerdo Ejecutivo de autorización. Este acuerdo debe ser publicado en el Diario Oficial La Gaceta por cuenta del interesado.13 Solo después de presentar la copia del recibo de publicación y el acuerdo certificado ante la Aduana, la agencia queda formalmente inscrita en el registro de auxiliares y habilitada para operar.13

### **Personal subalterno y asistentes**

Una agencia no opera solo con su agente regente; requiere asistentes debidamente acreditados. Estos deben poseer, al menos, un diplomado en administración aduanera (o técnico en caso de inopia).1 La agencia debe solicitar su inscripción mediante el formulario DER08, aportando pruebas de su formación, antecedentes penales y el contrato laboral vigente que los vincula a la empresa.4 Es vital entender que los asistentes solo pueden trabajar para una única agencia o agente independiente.15 Sus funciones incluyen efectuar exámenes previos de mercancías, asistir a reconocimientos físicos y gestionar consultas técnicas ante la autoridad.15

## **Gestión financiera y el sistema de garantías (Cauciones)**

Uno de los mayores obstáculos financieros para la fundación de una agencia es el esquema de garantías exigido por el Estado para asegurar el pago de eventuales tributos, multas o daños causados al fisco. La normativa establece que ningún auxiliar puede operar sin haber caucionado su responsabilidad.1

### **Montos de las garantías para 2026**

De acuerdo con la circular DGA-CIR-0020-2025, emitida en mayo de 2025, el cronograma de renovación y los montos se han actualizado para el periodo 2025-2026.21 Para las agencias de aduanas autorizadas a partir de mayo de 2021, el monto de la garantía es de **$20.000 USD** para operar en todas las aduanas del país.21 Este cambio simplificó el esquema anterior donde se pagaba por cada aduana individualmente, aunque las agencias antiguas aún pueden mantener montos de $10.000 por la aduana principal y $8.000 por adicionales si así lo prefieren, bajo el riesgo de perder beneficios de operación global.21

| Categoría de Auxiliar | Monto de Garantía (USD) | Base Legal / Observaciones |
| :---- | :---- | :---- |
| Agencia de Aduanas (Nueva) | $20.000 | Cobertura nacional total según CAUCA IV.21 |
| Agente Aduanero Independiente | $20.000 | Equivalente a 20.000 pesos centroamericanos.1 |
| Agentes Declarantes de Tránsito | $50.000 | Requisito específico para operaciones de tránsito interno.21 |
| Depositarios Aduaneros | $150.000 | Por cada ubicación física autorizada.21 |
| Empresas de Entrega Rápida | $20.000 | Régimen de courier y paquetería express.21 |

La garantía puede rendirse mediante diversos instrumentos financieros, siendo el seguro de caución y la garantía bancaria los más comunes. Es imperativo que el instrumento incluya textualmente lo señalado en el Artículo 89 del Reglamento a la Ley General de Aduanas, asegurando que la garantía sea exigible de forma inmediata ante cualquier incumplimiento.22

## **La revolución tecnológica: Hacienda Digital y el sistema ATENA**

El emprendedor de 2026 debe ser consciente de que Costa Rica ha dejado atrás los sistemas analógicos y los portales fragmentados. El proyecto Hacienda Digital ha unificado la gestión tributaria y aduanera en una arquitectura basada en la nube, inteligencia artificial y interoperabilidad total.3

### **TRIBU-CR: El nuevo corazón tributario**

A partir de finales de 2025, la plataforma TRIBU-CR reemplazó definitivamente al sistema ATV y al portal Travi.2 Para una agencia de aduanas, esto significa que toda su contabilidad fiscal, presentación de impuestos sobre la renta (que vence cada 15 de marzo) y gestión del IVA se centraliza aquí.2

Un cambio disruptivo es la automatización de la fiscalización. TRIBU-CR permite realizar cruces de información en tiempo real. Por ejemplo, la Declaración D-270 (antigua D-151), que recopila información sobre clientes y proveedores, ha pasado de ser anual a mensual.26 Cualquier inconsistencia entre lo que la agencia factura por sus honorarios y lo que el cliente declara como gasto es detectada inmediatamente por el sistema.26

### **ATENA: El reemplazo del sistema TICA**

En el ámbito estrictamente aduanero, el sistema TICA ha sido sustituido por ATENA.3 Este nuevo Sistema Integrado de Gestión Aduanera ha sido diseñado para mejorar la eficiencia mediante el uso de modelos de datos de la OMA y normas ISO 27001 de seguridad de la información.3

Los beneficios que ATENA aporta a la nueva agencia incluyen:

1. **Trazabilidad total**: Seguimiento de la carga desde el manifiesto hasta el levante final con mayor precisión.3  
2. **Gestión de Riesgo Inteligente**: El sistema utiliza algoritmos para determinar qué cargamentos requieren inspección física, reduciendo la discrecionalidad administrativa.3  
3. **Expediente Electrónico**: Es obligatorio adjuntar digitalmente todos los documentos de respaldo (facturas, CFDI, gastos de transporte) al pedimento, eliminando la necesidad de archivos físicos voluminosos.29

Para operar en este entorno, la agencia debe garantizar que sus equipos informáticos cumplan con requerimientos técnicos específicos (formatos RA22) y poseer licencias de software autorizadas para la transmisión electrónica de datos.11 El uso de la firma digital es absoluto; sin ella, es imposible validar cualquier declaración en el sistema.11

## **Localización estratégica y operatividad en Heredia**

La elección del domicilio fiscal y operativo no es un detalle menor. Heredia se ha consolidado como un centro logístico clave debido a su cercanía con aeropuertos y la concentración de zonas francas. No obstante, esto implica cumplir con regulaciones locales específicas.

### **Patentes y requerimientos municipales en Heredia**

La Municipalidad de Heredia exige una licencia comercial para cualquier oficina abierta al público. El trámite se realiza mediante una declaración jurada del impuesto de patente y requiere estar al día con todos los impuestos municipales y de seguridad social.31

| Requisito Municipal | Entidad Emisora | Observaciones para 2026 |
| :---- | :---- | :---- |
| Uso de Suelo | Municipalidad de Heredia | Debe verificarse que el local tiene permiso comercial/oficinas.32 |
| Permiso Sanitario | Ministerio de Salud | Vigente a nombre del solicitante.32 |
| Póliza de Riesgos | INS | Contrato y recibo vigente de la póliza patronal.32 |
| Certificación CCSS | Caja Costarricense del Seguro Social | Demostrar que no hay morosidad patronal.32 |
| Firma Digital | BCCR / Instituciones autorizadas | Necesaria para trámites en la plataforma digital municipal (CMV).33 |

Es importante notar que los profesionales liberales (agentes aduaneros persona física) pueden estar exentos de la licencia municipal bajo ciertas condiciones, siempre que estén incorporados a su colegio respectivo y realicen la actividad de forma estrictamente profesional.32

### **El Régimen de Zonas Francas (RZF)**

Si la agencia planea establecerse dentro de un parque industrial bajo el RZF, debe conocer los incentivos y las obligaciones de inversión. Las empresas en zona franca disfrutan de exoneraciones totales de impuestos de importación de maquinaria y materias primas, así como exenciones de impuestos municipales y de traspaso de bienes inmuebles por 10 años.34

Sin embargo, para calificar se requiere una inversión mínima significativa. Dentro de la Gran Área Metropolitana (GAM), que incluye la mayor parte de Heredia, la inversión inicial en activos fijos debe ser de al menos **$150.000 USD** si se ubica dentro de un parque industrial, o de **$2.000.000 USD** si se ubica fuera de parque de manera excepcional.35 Estas empresas deben generar empleo formal y presentar informes anuales ante PROCOMER y el Ministerio de Hacienda.34

## **Procedimientos operativos y facilitación del comercio**

La gestión diaria de una agencia de aduanas gira en torno al despacho de mercancías, un proceso que en 2026 está altamente automatizado pero que sigue requiriendo una supervisión técnica meticulosa.

### **Ventanilla Única de Comercio Exterior (VUCE 2.0)**

La VUCE es el sistema encargado de centralizar y simplificar los trámites previos al despacho.37 Mediante VUCE 2.0, la agencia gestiona las "notas técnicas" o permisos de importación y exportación requeridos por diversas instituciones gubernamentales. La plataforma permite pagos vía SINPE y el uso de firma digital para agilizar los procesos.28 En 2026, la meta es que el 80% de estos trámites se aprueben automáticamente mediante gestión de riesgo, eliminando cuellos de botella burocráticos.28

### **Clases de control aduanero**

La agencia debe estar preparada para enfrentar tres tipos de control definidos en la Ley 1:

1. **Control Inmediato**: Realizado durante el despacho de las mercancías, desde su ingreso hasta el levante autorizado.  
2. **Control a Posteriori**: Auditorías realizadas sobre las declaraciones aduaneras y la contabilidad de la agencia en los años siguientes al despacho.  
3. **Control Permanente**: Aplicado sobre los auxiliares que gestionan regímenes especiales como depósitos o zonas francas.

Un avance significativo en 2025-2026 ha sido el fortalecimiento del **Control Diferido**, el cual permite un despacho más ágil en frontera a cambio de una fiscalización exhaustiva una vez que la mercancía ha ingresado al mercado, lo que reduce tiempos y costos operativos para los importadores.39

## **El rol de las cámaras y la red de contactos**

Fundar una agencia de aduanas no debe ser un esfuerzo aislado. La afiliación a organizaciones gremiales como la Cámara de Agentes de Aduanas de Costa Rica o la Cámara de Comercio Exterior (CRECEX) ofrece beneficios estratégicos.40 Estas organizaciones brindan acceso a agendas de negocios, cálculos arancelarios, capacitaciones en etiquetado y embalaje, y representación ante las autoridades gubernamentales para la defensa de intereses del sector.40

Para afiliarse a CRECEX, por ejemplo, una persona jurídica debe completar una solicitud, presentar referencias comerciales que avalen su solvencia moral y profesional, y cancelar las cuotas de incorporación vigentes.42 Estas cámaras son vitales para mantenerse actualizado sobre las reformas legislativas y las tendencias del comercio global, como la inteligencia artificial aplicada a la logística y la biometría en los controles fronterizos.43

## **Infracciones, sanciones y gestión de riesgos**

El marco sancionatorio en Costa Rica es riguroso y busca castigar tanto la negligencia como la intención dolosa. El auxiliar que deje de cumplir con algún requisito general o específico después de ser autorizado no podrá operar hasta que demuestre haber subsanado el incumplimiento.1

### **Catálogo de sanciones y responsabilidades**

Las infracciones pueden derivar en multas económicas sustanciales, suspensiones temporales del ejercicio o incluso la cancelación definitiva de la autorización.45 El agente aduanero es civilmente responsable ante su mandante por cualquier lesión patrimonial derivada de su gestión.1 Además, si se detectan incongruencias relevantes entre los ingresos declarados, el patrimonio de la agencia y el volumen de operaciones, la autoridad puede iniciar procedimientos administrativos complejos o incluso penales por presunta defraudación fiscal.46

En 2026, ha surgido la necesidad de que las agencias implementen políticas de "debida diligencia" o "conocimiento del cliente" (KYC). La autoridad presiona para que el agente actúe como una extensión de su control, auditando la capacidad de sus clientes para generar el volumen de operaciones que declaran.44 Un error común es no contar con contratos de prestación de servicios formalizados que protejan el RFC y el padrón de importadores, lo que puede exponer a la agencia a responsabilidades por errores ajenos en la clasificación arancelaria u origen de las mercancías.47

### **Prevención y defensa legal**

Dada la complejidad del entorno, las agencias modernas suelen contar con asesoría legal especializada en materia fiscal y aduanera para la atención de controversias.46 La certificación ISO 9001 en los procesos internos de la agencia se ha convertido en una ventaja competitiva, garantizando calidad, consistencia y rigor metodológico en el manejo de expedientes electrónicos.46

## **Conclusiones para el establecimiento exitoso**

Establecer una agencia de aduanas en Costa Rica hoy requiere una visión 360 grados. El fundador debe asegurar no solo el cumplimiento de la letra de la Ley 7557, sino también la solvencia tecnológica para operar en ATENA y la disciplina fiscal para integrarse en TRIBU-CR. La ubicación estratégica en zonas como Heredia, el aprovechamiento de los incentivos de Zona Franca y la participación activa en cámaras sectoriales completan el perfil de una empresa preparada para los desafíos del comercio exterior en 2026\. La figura del agente aduanero ha trascendido el mero trámite documental para convertirse en un consultor estratégico y un guardián de la seguridad jurídica y fiscal del país.

#### **Fuentes citadas**

1. Ley General de Aduanas \- Sistema Costarricense de Información Jurídica, acceso: marzo 21, 2026, [https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm\_texto\_completo.aspx?nValor1=1\&nValor2=25886](https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?nValor1=1&nValor2=25886)  
2. Cómo se espera que Hacienda Digital cambie la gestión de impuestos en Costa Rica, acceso: marzo 21, 2026, [https://siemprealdia.co/costa-rica/impuestos/funcionamiento-hacienda-digital/](https://siemprealdia.co/costa-rica/impuestos/funcionamiento-hacienda-digital/)  
3. ATENA: El nuevo sistema aduanero digital de Costa Rica \- BLP Legal, acceso: marzo 21, 2026, [https://blplegal.com/es/atena-el-nuevo-sistema-aduanero-digital-de-costa-rica/](https://blplegal.com/es/atena-el-nuevo-sistema-aduanero-digital-de-costa-rica/)  
4. REQUISITOS PARA LA AUTORIZACION DE AGENTES ADUANEROS COMO AUXILIARES DE LA FUNCION PUBLICA ADUANERA \- Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/RA05REQUISITOSAUTORIZACIONCOMOENTIDADPUBLICA.doc](https://www.hacienda.go.cr/docs/RA05REQUISITOSAUTORIZACIONCOMOENTIDADPUBLICA.doc)  
5. ley 7557-ley general de aduanas \- Asamblea Legislativa, acceso: marzo 21, 2026, [https://www.asamblea.go.cr/sd/Documents/BIBLIOTECADIGITAL/DOCUMENTOS/LEYES/LEY%207557-LEY%20GENERAL%20DE%20ADUANAS.docx](https://www.asamblea.go.cr/sd/Documents/BIBLIOTECADIGITAL/DOCUMENTOS/LEYES/LEY%207557-LEY%20GENERAL%20DE%20ADUANAS.docx)  
6. Ley General de Aduanas Costa Rica: reglamento y exenciones \- Blog de Alegra, acceso: marzo 21, 2026, [https://blog.alegra.com/costa-rica/ley-general-de-aduanas-costa-rica/](https://blog.alegra.com/costa-rica/ley-general-de-aduanas-costa-rica/)  
7. N° 7557 LEY GENERAL DE ADUANAS LA ASAMBLEA LEGISLATIVA DE LA REPÚBLICA DE COSTA RICA DECRETA \- FAOLEX, acceso: marzo 21, 2026, [https://faolex.fao.org/docs/pdf/cos218199.pdf](https://faolex.fao.org/docs/pdf/cos218199.pdf)  
8. Histórico de Noticias \- Ministerio de Hacienda \- República de Costa Rica, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/HistoricoNoticias.html](https://www.hacienda.go.cr/HistoricoNoticias.html)  
9. Nº 25270-H Reglamento a la Ley General de Aduanas, acceso: marzo 21, 2026, [https://repositorio.mopt.go.cr/bitstreams/4615b92a-2d49-433f-84a3-08e39206ba38/download](https://repositorio.mopt.go.cr/bitstreams/4615b92a-2d49-433f-84a3-08e39206ba38/download)  
10. EL AGENTE ADUANERO, acceso: marzo 21, 2026, [https://cijulenlinea.ucr.ac.cr/portal/descargar.php?q=Mzk1](https://cijulenlinea.ucr.ac.cr/portal/descargar.php?q=Mzk1)  
11. REQUISITOS PARA LA AUTORIZACION DE AGENTES ADUANEROS COMO AUXILIARES DE LA FUNCION PUBLICA ADUANERA \- Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/RA03REQUISITOSAUTORIZACIONCOMOAGENTEADUANERODECLAR.doc](https://www.hacienda.go.cr/docs/RA03REQUISITOSAUTORIZACIONCOMOAGENTEADUANERODECLAR.doc)  
12. Las diferencias entre agente aduanal, apoderado aduanal y agencia aduanal, acceso: marzo 21, 2026, [https://www.garciayasociados.net/las-diferencias-entre-agente-aduanal-apoderado-aduanal-y-agencia-aduanal](https://www.garciayasociados.net/las-diferencias-entre-agente-aduanal-apoderado-aduanal-y-agencia-aduanal)  
13. REQUISITOS PARA LA AUTORIZACION DE AGENTES ADUANEROS COMO AUXILIARES DE LA FUNCION PUBLICA ADUANERA \- Ministerio de Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/RA01REQUISITOSAUTORIZACIONCOMOAGENTEADUANERO.doc](https://www.hacienda.go.cr/docs/RA01REQUISITOSAUTORIZACIONCOMOAGENTEADUANERO.doc)  
14. Administración Aduanera | Universidad Técnica Nacional | Costa Rica \- UTN, acceso: marzo 21, 2026, [https://www.utn.ac.cr/content/administracion-aduanera](https://www.utn.ac.cr/content/administracion-aduanera)  
15. Reglamento a la Ley General de Aduanas \- Sistema Costarricense de Información Jurídica, acceso: marzo 21, 2026, [https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm\_texto\_completo.aspx?param1=NRTC\&nValor1=1\&nValor2=99648\&nValor3=0\&strTipM=TC](https://pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?param1=NRTC&nValor1=1&nValor2=99648&nValor3=0&strTipM=TC)  
16. Incorporación en linea – CCECR \- Colegio de Ciencias Económicas, acceso: marzo 21, 2026, [https://www.colegiocienciaseconomicas.cr/incorporacion-en-linea/](https://www.colegiocienciaseconomicas.cr/incorporacion-en-linea/)  
17. Incorporación – Cronograma \- Colegio de Profesionales en Orientación, acceso: marzo 21, 2026, [https://www.cpocr.org/incorporacion/fechas/](https://www.cpocr.org/incorporacion/fechas/)  
18. REQUISITOS DE INCORPORACIÓN.docx \- Colegio de Ciencias Económicas, acceso: marzo 21, 2026, [https://www.colegiocienciaseconomicas.cr/documentos/incorporaciones/REQUISITOS%20DE%20INCORPORACI%C3%93N.docx](https://www.colegiocienciaseconomicas.cr/documentos/incorporaciones/REQUISITOS%20DE%20INCORPORACI%C3%93N.docx)  
19. Trámites \- Incorporación \- Colegio de Profesionales en Ciencias Políticas y Relaciones Internacionales, acceso: marzo 21, 2026, [https://cpri.cr/https-cpri-cr-tramite-incorporacion/](https://cpri.cr/https-cpri-cr-tramite-incorporacion/)  
20. REQUISITOS PARA LA AUTORIZACION DE AGENTES ADUANEROS COMO AUXILIARES DE LA FUNCION PUBLICA ADUANERA \- Ministerio de Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/RA04REQUISITOSAUTORIZACIONCOMOASISTENTEDEAGENTEADUANEROmayo2021.doc](https://www.hacienda.go.cr/docs/RA04REQUISITOSAUTORIZACIONCOMOASISTENTEDEAGENTEADUANEROmayo2021.doc)  
21. CIRCULAR MH-DGA-CIR-0020-2025 Mes Categoría de Auxiliar Monto (US$) JUAN CARLOS GOMEZ SANCHEZ (FIRMA) \- Ministerio de Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/MH-DGA-CIR-0020-2025.pdf](https://www.hacienda.go.cr/docs/MH-DGA-CIR-0020-2025.pdf)  
22. CIRCULAR MH-DGA-CIR-0034-2023 De: Dirección General de Aduanas Fecha \- Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/MH-DGA-CIR-0034-2023.pdf](https://www.hacienda.go.cr/docs/MH-DGA-CIR-0034-2023.pdf)  
23. Anexo. Información General del Proyecto Hacienda Digital, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/Anexo\_003-Informaci%C3%B3n\_General\_del\_PHD.pdf](https://www.hacienda.go.cr/docs/Anexo_003-Informaci%C3%B3n_General_del_PHD.pdf)  
24. De ATV a Tribu-CR: todos los cambios en el sistema de gestión tributaria digital, acceso: marzo 21, 2026, [https://www.proactivamrf.com/post/de-atv-a-tribu-cr-todos-los-cambios-en-el-sistema-de-gesti%C3%B3n-tributaria-digital](https://www.proactivamrf.com/post/de-atv-a-tribu-cr-todos-los-cambios-en-el-sistema-de-gesti%C3%B3n-tributaria-digital)  
25. Ministerio de Hacienda \- República de Costa Rica, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/](https://www.hacienda.go.cr/)  
26. Panorama tributario 2026: más control digital y nuevas obligaciones para los contribuyentes \- El poder de la información fiscal, acceso: marzo 21, 2026, [https://actualidadtributaria.com/?action=news-view\&id=1893](https://actualidadtributaria.com/?action=news-view&id=1893)  
27. Bienvenidos a \- Hacienda, acceso: marzo 21, 2026, [https://www.hacienda.go.cr/docs/InformacionsobreSistemaATENA.pdf](https://www.hacienda.go.cr/docs/InformacionsobreSistemaATENA.pdf)  
28. La digitalización en la facilitación del comercio en Costa Rica VUCE y Programa de Integración Fronteriza (PIF), acceso: marzo 21, 2026, [https://tfadatabase.org/en/uploads/thematicdiscussiondocument/ppt\_vuce\_y\_pi\_1.pdf](https://tfadatabase.org/en/uploads/thematicdiscussiondocument/ppt_vuce_y_pi_1.pdf)  
29. Paquete Económico 2026: iniciativa de reformas a la Ley Aduanera y la Ley de los Impuestos Generales de Importación y de Exportación para 2026 | EY México, acceso: marzo 21, 2026, [https://www.ey.com/es\_mx/technical/tax/boletines-fiscales/reformas-ley-aduanera-ley-impuestos-imp-exp](https://www.ey.com/es_mx/technical/tax/boletines-fiscales/reformas-ley-aduanera-ley-impuestos-imp-exp)  
30. Vuce 2.0, acceso: marzo 21, 2026, [https://vuce20.procomer.go.cr/](https://vuce20.procomer.go.cr/)  
31. Declaración Jurada del Impuesto de Patente Comercial Régimen Simplificado Físico | Portal Municipalidad de Heredia, acceso: marzo 21, 2026, [https://www.heredia.go.cr/es/tramites/servicios-tributarios/declaraci%C3%B3n-jurada-del-impuesto-de-patente-comercial-r%C3%A9gimen-0](https://www.heredia.go.cr/es/tramites/servicios-tributarios/declaraci%C3%B3n-jurada-del-impuesto-de-patente-comercial-r%C3%A9gimen-0)  
32. Solicitud de Licencia Comercial (Solicitudes nuevas) | Portal Municipalidad de Heredia, acceso: marzo 21, 2026, [https://www.heredia.go.cr/es/tramites/servicios-tributarios/solicitud-de-licencia-comercial-solicitudes-nuevas](https://www.heredia.go.cr/es/tramites/servicios-tributarios/solicitud-de-licencia-comercial-solicitudes-nuevas)  
33. ¿Cómo presentar la Declaración de Patentes? | Portal Municipalidad de Heredia, acceso: marzo 21, 2026, [https://www.heredia.go.cr/es/contactenos/preguntas-frecuentes/informaci%C3%B3n/%C2%BFc%C3%B3mo-presentar-la-declaraci%C3%B3n-de-patentes](https://www.heredia.go.cr/es/contactenos/preguntas-frecuentes/informaci%C3%B3n/%C2%BFc%C3%B3mo-presentar-la-declaraci%C3%B3n-de-patentes)  
34. Zonas Francas en Costa Rica: Ventajas Fiscales y Liderazgo en Transparencia Internacional \- bdo.cr, acceso: marzo 21, 2026, [https://www.bdo.cr/es-cr/publicaciones/2025/zonas-francas-en-costa-rica-ventajas-fiscales-y-liderazgo-en-transparencia-internacional](https://www.bdo.cr/es-cr/publicaciones/2025/zonas-francas-en-costa-rica-ventajas-fiscales-y-liderazgo-en-transparencia-internacional)  
35. Zona Franca en Costa Rica: Guía 2025 (Beneficios, Inversión Mínima, GAM vs. fuera del GAM) \- AG Legal, acceso: marzo 21, 2026, [https://aglegal.com/es/zona-franca/](https://aglegal.com/es/zona-franca/)  
36. GUÍA RÉGIMEN ZONA FRANCA | Procomer, acceso: marzo 21, 2026, [https://procomer.com/wp-content/uploads/2025/01/Guias-Zonas-Francas\_En25-ESP.pdf](https://procomer.com/wp-content/uploads/2025/01/Guias-Zonas-Francas_En25-ESP.pdf)  
37. Acerca de la Ventanilla Única de Comercio Exterior \- VUCE, acceso: marzo 21, 2026, [https://www.vuce.cr/acerca-de-vuce/](https://www.vuce.cr/acerca-de-vuce/)  
38. VUCE: Ventanilla Única de Comercio Exterior, trámites de exportación e importación en Costa Rica, acceso: marzo 21, 2026, [https://www.vuce.cr/](https://www.vuce.cr/)  
39. Nueva disposición aduanera agilizará trámites en Costa Rica. \- ICS Consultores, acceso: marzo 21, 2026, [https://ics.cr/nueva-disposicion-aduanera-agilizara-tramites-en-costa-rica/](https://ics.cr/nueva-disposicion-aduanera-agilizara-tramites-en-costa-rica/)  
40. CRECEX | Cámara de Comercio Exterior de Costa Rica, acceso: marzo 21, 2026, [https://crecex.com/](https://crecex.com/)  
41. AmCham – Cámara Costarricense – Norteamericana de Comercio, acceso: marzo 21, 2026, [https://www.amcham.cr/](https://www.amcham.cr/)  
42. Afiliación – Cámara de Comercio Exterior de Costa Rica y de Representantes de Casas Extranjeras \- CRECEX, acceso: marzo 21, 2026, [https://crecex.com/afiliacion/](https://crecex.com/afiliacion/)  
43. The 2026 Economic Package includes a comprehensive reform of customs. \- YouTube, acceso: marzo 21, 2026, [https://www.youtube.com/watch?v=OCsxLFk2HiA](https://www.youtube.com/watch?v=OCsxLFk2HiA)  
44. El cambio de rol de los Agentes Aduanales para el 2026 \- YouTube, acceso: marzo 21, 2026, [https://www.youtube.com/watch?v=1ml6HIHR-WU](https://www.youtube.com/watch?v=1ml6HIHR-WU)  
45. Cambios importantes de la Reforma a la Ley aduanera 2026 \- gpf asesoria de negocios, acceso: marzo 21, 2026, [https://www.gpfasesoria.com/post/cambios-importantes-de-la-reforma-a-la-ley-aduanera-2026](https://www.gpfasesoria.com/post/cambios-importantes-de-la-reforma-a-la-ley-aduanera-2026)  
46. Ley Aduanera 2026: Impacto de la Reforma \- ST STRATEGO | Asesoría Fiscal, Comercio Exterior y Aduanas, acceso: marzo 21, 2026, [https://www.stratego-st.com/articulos-especializados/ley-aduanera-2026/](https://www.stratego-st.com/articulos-especializados/ley-aduanera-2026/)  
47. ¿Indispensable hacer un contrato con el agente o agencia aduanal? \- YouTube, acceso: marzo 21, 2026, [https://www.youtube.com/watch?v=j1uMJ9ntA4o](https://www.youtube.com/watch?v=j1uMJ9ntA4o)