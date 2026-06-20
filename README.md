# 🐾 Sistema de Gestión de Clínica Veterinaria

Este repositorio contiene el diseño, estructura e implementación de una base de datos relacional robusta en **PostgreSQL** orientada a la administración completa de una clínica veterinaria. El sistema cubre desde el registro clínico de pacientes (mascotas) y propietarios, hasta la agenda de consultas, emisión de diagnósticos, control de tratamientos médicos, manejo de inventario y facturación.

---

## 🗂️ Estructura del Repositorio

El proyecto está organizado en 5 módulos o archivos SQL específicos que deben ejecutarse en el siguiente orden secuencial:

### 1. `proyecto_final_bdd_tablas.sql`
* **Descripción:** Contiene el esquema DDl completo de la base de datos.
* **Componentes clave:** Creación de todas las tablas normalizadas, definición de llaves primarias (`PK`), llaves foráneas (`FK`) con políticas de integridad, restricciones únicas (`UQ`) y validaciones de datos (`CHECK`) —incluyendo formatos de correo y protección de rangos de fechas lógicas—.

### 2. `proyecto_final_bdd_datos_actualizado.sql`
* **Descripción:** Script encargado de la limpieza previa (`TRUNCATE`) y la posterior inserción del set de datos masivos.
* **Componentes clave:** Contiene registros de prueba reales y exhaustivos para propietarios, mascotas, expedientes médicos, inventario de medicamentos y facturas, ideales para simular el entorno operativo de la clínica.

### 3. `proyecto_final_bdd_consultas.sql`
* **Descripción:** Set de consultas estructuradas de selección (`SELECT`) diseñadas para la extracción de información estratégica.
* **Componentes clave:** Consultas relacionales que emplean uniones (`JOIN`), agregaciones (`GROUP BY`), filtros avanzados (`HAVING`, `WHERE`) y subconsultas para responder a reportes clave del negocio (médicos, financieros y de pacientes).

### 4. `proyecto_final_bdd_funciones_y_procedimientos.sql`
* **Descripción:** Implementación de bloques de código reutilizables y programación modular en la base de datos.
* **Componentes clave:** Funciones (`FUNCTIONS`) orientadas a cálculos precisos y Procedimientos Almacenados (`STORED PROCEDURES`) para automatizar tareas operativas complejas (como flujos de facturación o cierres de caja) invocados directamente desde la lógica de la aplicación.

### 5. `proyecto_final_bdd_triggers.sql`
* **Descripción:** Definición de disparadores automáticos encargados de velar por la integridad de las reglas de negocio en tiempo real.
* **Componentes clave:** Mecanismos de control avanzados que actúan de forma automatizada ante eventos específicos:
  - *Seguridad Médica:* Validación de alertas por alergias de mascotas antes de asignar recetas.
  - *Auditoría Financiera:* Automatización y congelación de precios históricos de medicamentos.
  - *Control de Agenda:* Prevención de superposición de horarios en las citas de los veterinarios.

---

## 💻 Instrucciones de Despliegue y Uso

Para montar el proyecto de forma correcta en su entorno local, abra su gestor de bases de datos preferido (**DBeaver** o **pgAdmin 4**) y siga estrictamente este orden de ejecución de scripts:

1. Cree una base de datos limpia en su servidor PostgreSQL.
2. Ejecute el archivo estructural **`1. Tablas`** para levantar la arquitectura y restricciones.
3. _(Opcional)_ Ejecute el archivo **`5. Triggers`** antes de los datos para que queden activos en sus pruebas iniciales.
4. Corra el script **`2. Datos`** para poblar el sistema por completo.
5. Explore y verifique los reportes corriendo el archivo **`3. Consultas`**.
6. Compile el archivo **`4. Funciones y Procedimientos`** para habilitar los bloques reutilizables del sistema.
