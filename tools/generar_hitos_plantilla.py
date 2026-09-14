# -*- coding: utf-8 -*-
"""Genera lib/utils/hitos_plantilla.dart desde el catálogo de hitos CAIPI."""
from pathlib import Path

AREAS = [
    'Desarrollo Motor Grueso',
    'Desarrollo Motor Fino',
    'Desarrollo Cognitivo',
    'Lenguaje y Comunicación',
    'Socialización y Autoayuda (Autonomía)',
]

HITOS: dict[int, dict[str, list[str]]] = {
    3: {
        'Desarrollo Motor Grueso': [
            'Levantar la cabeza y el pecho estando boca abajo sostenido sobre sus antebrazos.',
            'Mantener la cabeza erguida de forma estable cuando se le sostiene en posición sentada.',
            'Realizar pataleos simétricos y vigorosos al estar acostado boca arriba.',
            'Girar parcialmente el cuerpo de lado estando acostado sobre la espalda.',
        ],
        'Desarrollo Motor Fino': [
            'Llevar las manos a la boca o a la línea media del cuerpo de manera espontánea.',
            'Sostener un sonajero colocado en su mano durante unos segundos de forma refleja.',
            'Mantener las manos abiertas o semiabiertas la mayor parte del tiempo.',
            'Seguir objetos o rostros con la mirada en un arco horizontal de 180 grados.',
        ],
        'Desarrollo Cognitivo': [
            'Responder a sonidos del entorno girando la cabeza o deteniendo su actividad.',
            'Explorar visualmente objetos cercanos y rostros de las personas con atención prolongada.',
            'Anticipar la alimentación al ver el biberón o el pecho materno.',
            'Demostrar curiosidad e interés activo por estímulos visuales brillantes o en movimiento.',
        ],
        'Lenguaje y Comunicación': [
            "Emitir balbuceos y sonidos guturales simples ('agu', 'eje', 'a-a').",
            'Sonreír vocalizando en respuesta al contacto verbal o cara a cara con un adulto.',
            'Expresar diferentes tipos de llanto según sus necesidades (hambre, sueño, malestar).',
            'Dirigir la mirada hacia la fuente de una voz conocida.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Responder con una sonrisa social intencionada ante rostros familiares y expresiones afectivas.',
            'Establecer y sostener contacto visual directo con sus cuidadores primarios.',
            'Calmarse gradualmente al ser tomado en brazos, mecido o al escucharle hablar suavemente.',
            'Mostrar agrado e interés por la interacción física y el juego relacional cara a cara.',
        ],
    },
    6: {
        'Desarrollo Motor Grueso': [
            'Girarse completamente sobre sí mismo (dar la vuelta de boca abajo a boca arriba y viceversa).',
            'Mantenerse sentado con apoyo mínimo o de forma independiente por breves momentos.',
            'Sostener su propio peso apoyando las piernas firmemente cuando se le sostiene erguido.',
            'Extender los brazos boca abajo para sostenerse sobre las palmas abiertas.',
        ],
        'Desarrollo Motor Fino': [
            'Alcanzar y agarrar objetos voluntariamente utilizando toda la palma (agarre palmar).',
            'Transferir objetos de una mano a la otra con facilidad.',
            'Sostener un objeto en cada mano simultáneamente.',
            'Llevarse juguetes y objetos directamente a la boca para explorarlos.',
        ],
        'Desarrollo Cognitivo': [
            'Buscar visualmente un objeto que ha dejado caer o que desaparece parcialmente de su vista.',
            'Explorar objetos activamente mediante el tacto, la vista y la agitación (sacudir, golpear).',
            'Demostrar reconocimiento claro de personas conocidas vs. desconocidos.',
            'Examinar sus propias manos y pies con detenimiento e interés prolongado.',
        ],
        'Lenguaje y Comunicación': [
            "Emitir balbuceos silábicos combinados ('ba-ba', 'da-da', 'ma-ma') de forma repetitiva.",
            'Responder a su nombre girando la cabeza o sonriendo cuando se le llama.',
            'Expresar emociones de alegría, frustración o protesta mediante vocalizaciones y tonos diferenciados.',
            'Realizar juegos de imitación de sonidos o entonaciones producidas por los adultos.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Sostener la teta del biberón o aproximar las manos al vaso de entrenamiento durante la alimentación.',
            'Comer alimentos semisólidos o papillas servidos con cuchara sin expulsarlos con la lengua.',
            "Disfrutar de los juegos interactivos de ocultamiento ('¿Dónde está el bebé?', 'Peek-a-boo').",
            'Extender los brazos espontáneamente hacia los adultos para pedir que lo levanten en brazos.',
        ],
    },
    9: {
        'Desarrollo Motor Grueso': [
            'Sentarse de forma independiente y estable sin apoyo durante periodos prolongados.',
            'Gatear de forma coordinada cruzando brazos y piernas alternadamente.',
            'Ponerse de pie sosteniéndose firmemente de muebles u objetos estables.',
            'Cambiar de posición solo: pasar de sentado a gateo o acostado sin perder el equilibrio.',
        ],
        'Desarrollo Motor Fino': [
            'Utilizar la pinza digital inferior (agarre entre la base del dedo índice y el pulgar).',
            'Golpear dos objetos entre sí en la línea media del cuerpo para producir sonido.',
            'Soltar objetos intencionadamente para que caigan o para entregarlos a un adulto.',
            'Apuntar hacia objetos o lugares utilizando el dedo índice extendido.',
        ],
        'Desarrollo Cognitivo': [
            'Buscar un objeto completamente escondido bajo una manta o recipiente (permanencia del objeto).',
            'Explorar detalles minúsculos de objetos o juguetes utilizando la punta de los dedos.',
            'Comprender la relación causa-efecto simple (presionar un botón para activar un sonido).',
            'Asociar gestos con acciones o rutinas cotidianas conocidas.',
        ],
        'Lenguaje y Comunicación': [
            "Comprender la palabra 'No' y detener momentáneamente su acción al escucharla.",
            "Utilizar gestos comunicativos sociales (decir 'adiós' con la mano, aplaudir, pedir 'dame').",
            'Imitar sonidos consonánticos y variaciones de entonación emitidas por los cuidadores.',
            'Responder vocalmente cuando se le habla o se le hace una pregunta simple.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Sostener galletas o trozos pequeños de alimentos blandos e introducirlos solos a la boca.',
            'Beber pequeños sorbos de un vaso sostenido por un adulto.',
            'Mostrar cautela o timidez ante personas extrañas y preferencia marcada por sus cuidadores.',
            'Colaborar durante el vestido extendiendo los brazos o piernas hacia las prendas.',
        ],
    },
    12: {
        'Desarrollo Motor Grueso': [
            'Caminar sostenido de una mano o dar sus primeros pasos independientes sin apoyo.',
            'Ponerse de pie desde el suelo sin apoyarse de muebles ni apoyos externos.',
            'Agacharse a recoger un juguete del suelo y ponerse de pie nuevamente sin caerse.',
            'Dar pasos laterales mientras se sostiene de los muebles (marcha de crucero).',
        ],
        'Desarrollo Motor Fino': [
            'Utilizar la pinza digital superior o fina (agarre preciso con las yemas del pulgar e índice).',
            'Introducir objetos o cuentas pequeñas dentro de un recipiente con boca angosta.',
            'Intentar hacer garabatos espontáneos sobre el papel utilizando un crayón grueso.',
            'Ohojear un libro de páginas rígidas de cartón pasando de a varias páginas a la vez.',
        ],
        'Desarrollo Cognitivo': [
            "Seguir instrucciones sencillas de un solo paso acompañadas de gestos ('Ven aquí', 'Dame la pelota').",
            'Utilizar objetos de manera funcional e intencionada (usar la cuchara, ponerse el teléfono al oído).',
            'Encontrar objetos ocultos tras múltiples desplazamientos simples.',
            'Asociar formas básicas o introducir bloques en encajables simples de una sola figura.',
        ],
        'Lenguaje y Comunicación': [
            "Decir de 2 a 4 palabras con significado claro e intencional ('mamá', 'papá', 'agua', 'no').",
            'Utilizar jerigonza con entonación expresiva similar a la conversación adulta.',
            'Señalar objetos o imágenes para pedir ayuda, mostrar interés o compartir atención.',
            'Reconocer y reaccionar al escuchar los nombres de personas y objetos cotidianos.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Comer alimentos sólidos pequeños con los dedos de manera autónoma.',
            'Sostener un vaso con ambas manos y beber líquidos con derrames mínimos.',
            'Ofrecer juguetes a los adultos en interacción, aunque a veces no desee soltarlos.',
            'Quitarse prendas de vestir sencillas como calcetines, gorros o zapatitos sueltos.',
        ],
    },
    18: {
        'Desarrollo Motor Grueso': [
            'Caminar con total independencia, seguridad y buena coordinación de manera continua.',
            'Correr con pasos rígidos y acelerados, deteniéndose antes de chocar con obstáculos.',
            'Subir escaleras gateando o tomado de la mano del adulto colocándose de pie en cada escalón.',
            'Patear una pelota grande sin perder el equilibrio.',
        ],
        'Desarrollo Motor Fino': [
            'Construir torres de 3 a 4 cubos de madera o bloques encajables.',
            'Realizar garabatos circulares y líneas espontáneas con crayones o lápices.',
            'Tapar y destapar frascos o recipientes con roscas sencillas.',
            'Insertar aros en un eje vertical o cuentas grandes en una tira gruesa.',
        ],
        'Desarrollo Cognitivo': [
            'Identificar y señalar partes básicas de su cuerpo (cabeza, ojos, nariz, boca) cuando se le solicita.',
            'Clasificar objetos por categoría o color primario mediante emparejamiento directo.',
            'Resolver rompecabezas sencillos de 2 a 3 piezas de encaje de madera.',
            'Imitar acciones domésticas sencillas (barrer, limpiar, alimentar a un muñeco).',
        ],
        'Lenguaje y Comunicación': [
            'Poseer un vocabulario de al menos 10 a 20 palabras funcionales con significado constante.',
            "Combinar dos palabras para expresar necesidades o deseos ('más leche', 'papá va').",
            'Identificar y señalar imágenes de objetos conocidos en libros ilustrados.',
            'Comprender órdenes simples sin requerir apoyo de gestos gráficos.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Comer solo utilizando cuchara de manera funcional, sufriendo pocos derrames.',
            'Avisar con gestos o palabras cuando tiene el pañal sucio o mojado.',
            'Ayudar a recoger sus juguetes al finalizar la actividad con guía del adulto.',
            'Lavar y secar sus manos con ayuda y supervisión directa.',
        ],
    },
    24: {
        'Desarrollo Motor Grueso': [
            'Correr con fluidez, esquivando obstáculos y cambiando de dirección sin caerse.',
            'Subir y bajar escaleras apoyando ambos pies en cada escalón y sosteniéndose del pasamanos.',
            'Saltar con ambos pies juntos despegándose completamente del suelo.',
            'Lanzar una pelota por encima de la cabeza hacia una dirección determinada.',
        ],
        'Desarrollo Motor Fino': [
            'Construir torres de 6 a 7 cubos de madera.',
            'Copiar trazos verticales y horizontales simples sobre el papel.',
            'Pasar las páginas de un libro de una en una con cuidado.',
            'Desenroscar tapas y manipular pestillos simples en juguetes u objetos.',
        ],
        'Desarrollo Cognitivo': [
            "Comprender el concepto de cantidades elementales ('uno', 'muchos').",
            'Identificar formas geométricas básicas (círculo, cuadrado, triángulo) en tablero de encaje.',
            "Seguir instrucciones de dos pasos consecutivos relacionados ('Recoge la pelota y ponla en la caja').",
            'Demostrar memoria espacial recordando dónde se guardaron sus juguetes favoritos.',
        ],
        'Lenguaje y Comunicación': [
            "Utilizar frases cortas de 3 a 4 palabras estructuradas ('Quiero comer manzana').",
            "Utilizar pronombres personales e interrogativos ('mío', 'yo', '¿qué es?').",
            'Comprender un vocabulario receptivo de más de 200 palabras cotidianas.',
            "Responder correctamente a preguntas simples sobre objetos o imágenes ('¿Dónde está el perro?').",
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Iniciar el proceso de control de esfínteres diurno (expresar ganas de ir al baño).',
            'Ponerse prendas sencillas de vestir (zapatos sin agujeta, pantalones elásticos).',
            'Usar la cuchara y el tenedor infantil con buena efectividad durante las comidas.',
            'Participar en juegos en paralelo al lado de otros niños compartiendo el espacio.',
        ],
    },
    30: {
        'Desarrollo Motor Grueso': [
            'Saltar desde un escalón o pequeña altura cayendo sobre ambos pies con amortiguación.',
            'Caminar sobre una línea recta trazada en el suelo manteniendo el equilibrio.',
            'Sostenerse sobre un solo pie por 2 a 3 segundos de manera estable.',
            'Pedalear en un triciclo pequeño o coche de empuje con pies.',
        ],
        'Desarrollo Motor Fino': [
            'Construir torres de 8 a 10 cubos de madera.',
            'Copiar trazos en forma de cruz (+), círculos cerrados y líneas diagonales.',
            'Sostener el lápiz con pinza trípode en desarrollo (entre los dedos en lugar de la palma).',
            'Iniciar el uso de tijeras infantiles realizando cortes simples en papel.',
        ],
        'Desarrollo Cognitivo': [
            'Identificar y nombrar al menos 4 colores primarios correctamente.',
            "Comprender conceptos espaciales básicos ('arriba', 'abajo', 'dentro', 'fuera').",
            'Completar rompecabezas de 4 a 6 piezas encajables.',
            'Clasificar objetos por dos atributos combinados (color y tamaño).',
        ],
        'Lenguaje y Comunicación': [
            'Expresar oraciones de 4 a 5 palabras utilizando plurales y tiempos verbales básicos.',
            "Preguntar de manera insistente usando '¿por qué?', '¿dónde?' y '¿quién?'.",
            'Mencionar su nombre completo y edad cuando se le pregunta.',
            'Relatar experiencias inmediatas cotidianas con coherencia comprensible para extraños.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Controlar esfínteres durante el día de forma autónoma avisando con anticipación.',
            'Lavarse y secar las manos solo usando agua y jabón.',
            'Desabrochar botones grandes y bajarse los pantalones para ir al baño.',
            'Participar en juegos simbólicos representativos (jugar a la comidita, doctores).',
        ],
    },
    36: {
        'Desarrollo Motor Grueso': [
            'Pedalear con fluidez en un triciclo avanzando en superficies planas.',
            'Subir escaleras alternando un pie en cada escalón sin sostenerse del pasamanos.',
            'Saltar hacia adelante con ambos pies cubriendo una distancia de más de 30 cm.',
            'Atrapar una pelota grande con ambas manos y los brazos extendidos contra el pecho.',
        ],
        'Desarrollo Motor Fino': [
            'Copiar una figura en forma de círculo (O) y líneas en cruz (+) con precisión.',
            'Manipular la plastilina realizando tiras, bolitas o formas sencillas.',
            'Enhebrar cuentas medianas en un cordón rígido o agujeta fina.',
            'Cortar una tira de papel en dos partes utilizando tijeras infantiles con una mano.',
        ],
        'Desarrollo Cognitivo': [
            'Contar hasta 5 objetos uno a uno mediante correspondencia término a término.',
            "Comprender nociones de tamaño ('grande', 'mediano', 'pequeño') y cantidad ('más', 'menos').",
            'Reconocer y nombrar las formas geométricas fundamentales (círculo, cuadrado, triángulo).',
            'Diferenciar entre niño y niña e identificarse a sí mismo según su género.',
        ],
        'Lenguaje y Comunicación': [
            'Mantener una conversación fluida respondiendo preguntas sobre temas de su interés.',
            "Utilizar adecuadamente preposiciones ('en', 'sobre', 'debajo'), pronombres y plurales.",
            'Recitar o cantar canciones infantiles cortas y rimas sencillas de memoria.',
            'Explicar lo que está sucediendo en láminas o ilustraciones de un cuento.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Comer de forma completamente independiente usando cubiertos sin derramar alimentos.',
            'Ponerse los zapatos solo (sin agujetas) y prendas sencillas de vestir sin ayuda.',
            'Compartir juguetes y turnos en juegos dirigidos con ayuda de adultos.',
            'Ir al sanitario de forma independiente, requiriendo ayuda únicamente para la limpieza.',
        ],
    },
    42: {
        'Desarrollo Motor Grueso': [
            'Mantenerse sobre un solo pie durante 5 segundos continuos sin caerse.',
            'Bajar escaleras alternando un pie en cada escalón con seguridad.',
            'Saltar en un pie consecutivamente 2 o 3 veces.',
            'Lanzar una pelota con fuerza y dirección precisa hacia un objetivo a 2 metros.',
        ],
        'Desarrollo Motor Fino': [
            'Copiar una figura geométrica de cuadrado (□) respetando esquinas y lados rectos.',
            'Dibujar a una persona representada con al menos 3 a 4 partes (cabeza, piernas, brazos).',
            'Usar la pinza trípode adecuada al sostener lápices, colores o pinceles.',
            'Recortar a lo largo de una línea recta de 10 cm trazada en papel.',
        ],
        'Desarrollo Cognitivo': [
            'Contar de forma concreta hasta 10 objetos asegurando la correspondencia uno a uno.',
            "Comprender conceptos temporales simples ('hoy', 'mañana', 'día', 'noche').",
            'Clasificar un grupo heterogéneo de objetos según dos criterios (ej. por forma y luego por color).',
            'Armar rompecabezas de 8 a 12 piezas de cartón o madera.',
        ],
        'Lenguaje y Comunicación': [
            'Expresar oraciones complejas de 5 a 6 palabras usando tiempos pasados correctamente.',
            'Relatar el argumento básico de un cuento conocido o una película infantil.',
            'Articular con claridad la mayoría de las consonantes de su idioma nativo.',
            'Comprender y ejecutar órdenes de 3 pasos consecutivos.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Abrochar y desabrochar botones medianos en sus prendas de vestir.',
            'Servirse agua o líquidos desde una jarra pequeña a su vaso con control.',
            "Participar en juegos sociodramáticos complejos asumiendo roles definidos ('papá', 'doctor').",
            'Expresar y verbalizar sus emociones (alegría, tristeza, enojo) antes de actuar impulsivamente.',
        ],
    },
    48: {
        'Desarrollo Motor Grueso': [
            'Correr, frenar y cambiar de dirección instantáneamente sin tambalearse.',
            'Atrapar una pelota que rebota en el suelo con ambas manos de forma segura.',
            'Caminar sobre una barra de equilibrio o borde angosto sin perder la postura.',
            'Dar saltos de longitud hacia adelante impulsándose con ambos pies al mismo tiempo.',
        ],
        'Desarrollo Motor Fino': [
            'Copiar una figura en forma de cruz en diagonal (X) y un cuadrado perfecto.',
            'Dibujar a la figura humana con 6 o más partes del cuerpo visibles y detalladas.',
            'Recortar siluetas de figuras geométricas simples (círculos, cuadrados) siguiendo el contorno.',
            'Escribir o copiar algunas letras mayúsculas de su nombre.',
        ],
        'Desarrollo Cognitivo': [
            'Identificar y nombrar al menos 8 colores y todas las formas geométricas planas.',
            "Comprender la noción de secuencia y orden temporal ('primero', 'después', 'al final').",
            'Resolver acertijos de lógica visual y patrones sencillos (ej. ABAB).',
            'Contar verbalmente hasta el número 15 o 20 de memoria.',
        ],
        'Lenguaje y Comunicación': [
            'Hablar de manera fluida y totalmente clara, comprensible incluso para personas desconocidas.',
            "Formular preguntas complejas sobre causa y efecto ('¿por qué sucede...?', '¿para qué sirve...?').",
            'Utilizar correctamente el futuro, condicional y adverbios en sus conversaciones.',
            "Definir palabras sencillas por su uso o función ('un cuchillo sirve para cortar').",
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Vestirse y desvestirse solo completamente, incluyendo subir y bajar cierres.',
            'Lavarse los dientes con cepillo e higiene personal con supervisión ligera.',
            'Interactuar y cooperar con grupos de 3 o más niños compartiendo recursos y espacios.',
            'Proponer soluciones pacíficas ante pequeños conflictos con sus compañeros de juego.',
        ],
    },
    54: {
        'Desarrollo Motor Grueso': [
            'Saltar en un solo pie durante 8 a 10 segundos continuos.',
            'Galopar y saltar alternando los pies con coordinación rítmica.',
            'Lanzar una pelota a un blanco u objetivo elevado con precisión.',
            'Subir y bajar estructuras de parque infantil (escaleras, pasamanos) con agilidad.',
        ],
        'Desarrollo Motor Fino': [
            'Copiar la figura geométrica de un triángulo (△) con trazos definidos y ángulos limpios.',
            'Escribir su nombre de pila en mayúsculas sin necesidad de plantilla visual.',
            'Doblar una hoja de papel a la mitad de borde a borde coincidiendo los extremos.',
            'Usar herramientas escolares (sacapuntas, regla, barras de pegamento) de forma precisa.',
        ],
        'Desarrollo Cognitivo': [
            'Contar conjuntos de más de 15 objetos mediante correspondencia uno a uno.',
            'Comprender la conservación de cantidad elemental en masa o líquidos.',
            'Armar rompecabezas de 15 a 20 piezas interconectadas.',
            'Identificar las estaciones del año y condiciones del clima asociadas.',
        ],
        'Lenguaje y Comunicación': [
            'Construir narraciones complejas manteniendo una estructura de inicio, desarrollo y desenlace.',
            'Utilizar correctamente sinfones consonánticos (ej. pl, bl, tr, cr).',
            'Identificar algunos sonidos de letras e iniciar la conciencia fonológica de rimas.',
            'Explicar reglas de juegos o normas sencillas a otros compañeros de su edad.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Utilizar el cuchillo de mesa sin filo para untar o cortar alimentos blandos.',
            'Bañarse solo con mínima asistencia para áreas difíciles como el cabello.',
            'Mostrar empatía activa reconociendo y reconfortando a compañeros tristes o lastimados.',
            'Aceptar las reglas de juegos competitivos sin presentar conductas destructivas.',
        ],
    },
    60: {
        'Desarrollo Motor Grueso': [
            'Saltar la cuerda con ambos pies juntos de manera coordinada.',
            'Mantener el equilibrio sobre un solo pie durante 10 segundos o más con los ojos cerrados.',
            'Rebotar, lanzar y atrapar una pelota pequeña (como una pelota de tenis) con una sola mano o alternando manos.',
            'Moverse con agilidad y fluidez combinando saltos, giros y galopes en circuitos de psicomotricidad.',
            'Dar volteretas hacia adelante (rodadas) sobre una colchoneta de forma segura.',
            'Subir y bajar escaleras corriendo o a paso rápido alternando los pies sin sostenerse.',
        ],
        'Desarrollo Motor Fino': [
            'Dibujar una figura humana completa y estructurada con al menos 12 a 15 detalles (cabeza, tronco, extremidades con proporciones básicas, manos con dedos, ropa y rasgos faciales detallados).',
            'Copiar números, letras mayúsculas e iniciar el trazo de su nombre de pila en manuscrito o imprenta.',
            'Recortar figuras geométricas complejas y siluetas detalladas siguiendo contornos finos.',
            'Atar las agujetas de los zapatos o hacer nudos sencillos con cordones.',
            'Utilizar herramientas escolares (lápiz, regla, sacapuntas, pegamento en barra) con excelente precisión y control de la presión.',
            'Doblar una hoja de papel en cuatro partes o realizar origami básico.',
        ],
        'Desarrollo Cognitivo': [
            'Contar de forma verbal y concreta mediante correspondencia uno a uno más de 20 objetos.',
            'Nombrar los días de la semana en orden cronológico y comprender la noción de días laborables vs. fin de semana.',
            'Clasificar conjuntos de objetos simultáneamente por tres atributos (ej. forma, color y tamaño).',
            'Comprender la conservación de la cantidad básica (saber que la cantidad de agua o masa no cambia al cambiar de recipiente o forma).',
            'Completar rompecabezas de 20 a 30 piezas interconectadas.',
            'Distinguir entre realidad y fantasía en cuentos, películas o narraciones cotidianas.',
        ],
        'Lenguaje y Comunicación': [
            'Expresar oraciones complejas de más de 8 palabras utilizando tiempos verbales pasados, presentes y futuros con adecuada concordancia gramatical.',
            "Comprender y utilizar correctamente conceptos de relación espacial y lógica ('a la derecha', 'a la izquierda', 'al lado de', 'entre').",
            'Articular correctamente todos los fonemas del idioma (incluyendo sinfones como cl, pl, tr, fr y la r/rr en consolidación).',
            "Relatar una historia o cuento largo siguiendo una secuencia temporal precisa y respondiendo a preguntas analíticas ('¿Qué habría pasado si...?').",
            "Definir objetos por su categoría o composición ('Un tenedor es un utensilio de metal para comer').",
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Aseo e higiene personal totalmente independiente (bañarse con supervisión mínima, lavarse los dientes correctamente y usar el sanitario de forma autónoma).',
            'Vestirse y desvestirse solo por completo, seleccionando prendas adecuadas según el clima o la ocasión.',
            'Acatar y respetar las reglas de juegos competitivos o de mesa sencillos (lotería, memorama, dominó infantil) aceptando la derrota sin frustración desmedida.',
            'Mostrar empatía activa, consolar a sus pares y cooperar en proyectos grupales prolongados.',
            "Realizar encargos sencillos fuera de su vista inmediata (ej. 'Ve a la dirección y pídele una hoja a la maestra').",
        ],
    },
    66: {
        'Desarrollo Motor Grueso': [
            'Saltar en un solo pie avanzando de forma sostenida y controlada más de 4 metros alternando de pie sin perder el equilibrio.',
            'Marchar y desplazarse marcando ritmos complejos, cambiando de dirección o velocidad al escuchar un estímulo sonoro o señal visual.',
            'Atrapar al vuelo y con una sola mano una pelota pequeña o de esponja lanzada desde una distancia de 2 metros.',
            'Esquivar obstáculos con agilidad durante carreras rápidas y realizar paradas en seco sobre una señal dada.',
            'Trepar en estructuras de juegos infantiles (pasamanos, redes o redes de escalar) utilizando la alternancia de manos y pies.',
            'Mantenerse en equilibrio sobre la punta de los pies durante 10 segundos continuos sin tambalearse.',
        ],
        'Desarrollo Motor Fino': [
            'Dibujar la figura humana con representación completa de la vestimenta, detalles anatómicos (cuello, orejas, pestañas, cejas, articulaciones) y proporciones ajustadas.',
            'Copiar letras del alfabeto (mayúsculas y minúsculas) y números del 1 al 10 respetando la direccionalidad del trazo.',
            'Recortar siluetas complejas con curvas cerradas, ángulos agudos o detalles pequeños utilizando tijeras con control preciso.',
            'Atar de manera independiente las agujetas de los zapatos realizando el lazo doble o moño completo.',
            'Sostener el lápiz con pinza trípode madura y perfecta autorregulación de la presión sobre la hoja.',
            'Abrochar broches a presión, cierres invisibles y abotonar prendas con botones pequeños o ajustados.',
        ],
        'Desarrollo Cognitivo': [
            'Contar de forma concreta mediante correspondencia término a término conjuntos de hasta 30 objetos o más.',
            'Reconocer y escribir los números del 1 al 10 vinculándolos directamente con su cantidad real.',
            'Nombrar en secuencia lógica los meses del año y asociar eventos cotidianos con estaciones o momentos del año.',
            'Comprender y aplicar la noción de seriación por longitud, peso o volumen en conjuntos de 5 a 7 elementos.',
            "Comprender enunciados de adición y sustracción sencillos con material concreto ('Si tienes 3 manzanas y te dan 2 más, ¿cuántas tienes?').",
            "Comprender conceptos de tiempo abstracto ('hace una semana', 'en un mes', 'pronto').",
        ],
        'Lenguaje y Comunicación': [
            "Expresar oraciones complejas con corrección sintáctica, utilizando conectores causales, temporales y condicionales ('porque', 'entonces', 'aunque', 'si acaso').",
            'Comprender la conciencia fonológica inicial: identificar rimas, aislar el sonido inicial de las palabras y segmentar palabras sencillas en sílabas.',
            'Producir todos los fonemas de la lengua materna con precisión, incluyendo la distinción clara entre la r simple y la rr múltiple.',
            "Explicar el significado de términos abstractos o funcionales ('¿Qué es la valentía?', '¿Para qué sirve el dinero?').",
            'Relatar sucesos o historias largas de manera organizada, coherente y enriquecida con vocabulario variado.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Manejar el dinero de mentira o real en situaciones simuladas de compra y venta, comprendiendo el concepto de intercambio.',
            'Bañarse, lavarse el cabello y secarse solo con supervisión mínima de un adulto.',
            'Acatar reglas de convivencia social y de juegos de mesa grupales respetando turnos, aceptando ganar o perder sin berrinches.',
            'Resolver conflictos interpersonales con sus pares mediante el diálogo y la negociación sin recurrir a agresiones verbales o físicas.',
            'Asumir tareas de responsabilidad dentro del aula o del hogar de manera independiente (limpiar su espacio de trabajo, preparar su mochila escolar, alimentar a una mascota).',
        ],
    },
    72: {
        'Desarrollo Motor Grueso': [
            'Saltar la cuerda de manera fluida y continua de forma individual o en grupo.',
            'Montar y coordinar la conducción de una bicicleta de dos ruedas sin ruedas de entrenamiento.',
            'Demostrar equilibrio dinámico avanzado (caminar hacia atrás sobre una viga angosta o borde elevado con las manos en la cintura).',
            'Rebotar, lanzar y atrapar pelotas de distintos tamaños en movimiento con una o dos manos en juegos colectivos.',
            'Realizar circuitos motores continuos combinando volteretas, saltos en un pie, galopes y cambios de dirección rápidos.',
            'Demostrar coordinación ojo-pie precisa al patear objetos en movimiento o dirigir balones a metas específicas.',
        ],
        'Desarrollo Motor Fino': [
            'Escribir su nombre completo de memoria y copiar frases cortas o palabras simples manteniendo el alineamiento sobre el renglón.',
            'Dibujar una figura humana completa, proporcional y detailed, añadiendo elementos del entorno con perspectiva básica.',
            'Manipular herramientas y materiales finos con alta precisión (utilizar sacapuntas, usar regla para trazar líneas rectas, recortar formas intrincadas).',
            'Amarrar las agujetas del calzado con firmeza y soltura.',
            'Colorear respetando límites complejos con control fino de la presión y del trazo.',
            'Plegar papel siguiendo secuencias de varios pasos (origami o figuras de papiroflexia sencillas).',
        ],
        'Desarrollo Cognitivo': [
            'Contar de forma verbal y concreta de 30 a 50 objetos, e iniciar el conteo de 2 en 2 o de 10 en 10.',
            'Resolver operaciones matemáticas elementales (sumas y restas sencillas hasta el número 10) con y sin apoyo de material concreto.',
            'Identificar y nombrar la hora aproximada en un reloj (reconocer horas en punto y medias horas).',
            'Clasificar objetos según criterios múltiples abstractos y explicar relaciones de causa-efecto en situaciones de la vida cotidiana.',
            'Reconocer y nombrar el valor de las monedas y billetes comunes de su entorno social.',
            'Comprender la secuencia temporal de un calendario (días, semanas, meses, ayer/hoy/mañana).',
        ],
        'Lenguaje y Comunicación': [
            'Expresar oraciones complejas y coordinadas con corrección sintáctica, gramatical y amplia variedad de vocabulario.',
            'Desarrollar habilidades de conciencia fonológica avanzada (identificar sonidos iniciales, finales y medios en las palabras, así como rimas y sílabas).',
            'Iniciar el proceso de lectura formal (reconocer palabras completas de uso frecuente y leer enunciados simples).',
            'Articular adecuadamente todos los fonemas de su lengua materna (incluyendo sinfones complejos y la r/rr).',
            'Explicar conceptos abstractos, expresar opiniones personales argumentadas y narrar cuentos largos respetando el orden lógico y temporal.',
        ],
        'Socialización y Autoayuda (Autonomía)': [
            'Realizar su rutina de higiene personal completa de forma autónoma (bañarse, lavarse el cabello, cepillarse los dientes y limpiarse en el sanitario).',
            'Seleccionar su ropa adecuadamente según el clima o la ocasión y vestirse/desvestirse completamente solo sin ayuda.',
            'Respetar y acatar reglas de juegos cooperativos y de mesa complejos (juegos de estrategia infantiles, cartas, damas), gestionando adecuadamente la frustración.',
            'Mostrar empatía, ofrecer ayuda espontánea a otros niños o adultos y cooperar activamente en proyectos de grupo.',
            'Cruzar la calle de la mano con precaución, respetando las normas de seguridad vial básicas expuestas por adultos.',
        ],
    },
}


def dart_string(s: str) -> str:
    if "'" in s and '"' not in s:
        return f'"{s}"'
    if '"' in s and "'" not in s:
        return f"'{s}'"
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def emit_tramo(meses: int, data: dict[str, list[str]]) -> list[str]:
    lines = [f'    HitosTramo({meses}, [']
    for area in AREAS:
        items = data[area]
        lines.append(f'      HitosArea({dart_string(area)}, [')
        for item in items:
            lines.append(f'        {dart_string(item)},')
        lines.append('      ]),')
    lines.append('    ]),')
    return lines


def main() -> None:
    out = Path(__file__).resolve().parents[1] / 'lib' / 'utils' / 'hitos_plantilla.dart'
    lines = [
        '/// Catálogo de hitos del desarrollo por edad (meses) — contenido CAIPI.',
        '/// Usado al cargar plantilla desde la app.',
        'class HitosArea {',
        '  final String nombre;',
        '  final List<String> items;',
        '  const HitosArea(this.nombre, this.items);',
        '}',
        '',
        'class HitosTramo {',
        '  final int meses;',
        '  final List<HitosArea> areas;',
        '  const HitosTramo(this.meses, this.areas);',
        r"  String get titulo => 'Hitos $meses meses';",
        '}',
        '',
        'class HitosPlantilla {',
        '  HitosPlantilla._();',
        '',
        '  static const List<HitosTramo> tramos = [',
    ]
    for meses in sorted(HITOS):
        lines.extend(emit_tramo(meses, HITOS[meses]))
    lines.extend([
        '  ];',
        '',
        '  static HitosTramo? porMeses(int meses) {',
        '    for (final t in tramos) {',
        '      if (t.meses == meses) return t;',
        '    }',
        '    return null;',
        '  }',
        '',
        '  static List<int> get mesesDisponibles =>',
        '      tramos.map((t) => t.meses).toList(growable: false);',
        '}',
        '',
    ])
    out.write_text('\n'.join(lines), encoding='utf-8')
    print(f'Wrote {out} ({len(lines)} lines)')


if __name__ == '__main__':
    main()
