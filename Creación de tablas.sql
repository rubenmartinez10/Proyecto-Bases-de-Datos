create table propietario(
    id_propietario bigint generated always as identity, --pk
    
    DUI varchar(10) not null, --uq
    nombre varchar(255) not null,
    apellido varchar(255) not null,
    telefono varchar(15),
    email varchar(255), --uq, ck
    direccion varchar(255),
    fecha_nacimiento_propietario date,
    
    constraint pk_id_propietario primary key(id_propietario),
    constraint uq_DUI_propietario unique(DUI),
    constraint uq_email_propietario unique(email),
    constraint ck_email_propietario check(email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

create table especie(
	id_especie bigint not null generated always as identity, --pk
	
	nombre varchar(255) not null, --uq
	descripcion text,
	
	constraint pk_id_especie primary key(id_especie),
	constraint uq_nombre_especie unique(nombre)
);


create table raza(
	id_raza bigint generated always as identity, --pk
	id_especie bigint not null, --fk
	
	nombre varchar(255) not null,
	
	constraint pk_id_raza primary key(id_raza),
	
	constraint fk_id_especie foreign key(id_especie) references especie(id_especie)
	on delete restrict
	on update cascade
);


create table mascota(
	id_mascota bigint generated always as identity, --pk
	id_propietario bigint not null, --fk
	id_raza bigint not null, --fk
	
	nombre varchar(255) not null,
	sexo char(1) not null, --ck
	peso_actual numeric(7,2), --ck
	fecha_nacimiento date,
	estado_reproductivo varchar(20), --ck
	descripcion_fisica text,
	
	constraint pk_id_mascota primary key(id_mascota),
	constraint ck_sexo check(sexo in ('M','F')),
	constraint ck_peso check(peso_actual > 0),
	constraint ck_estado_reproductivo check(estado_reproductivo in ('No esterilizado','Esterilizado')),
	
	constraint fk_id_propietario foreign key(id_propietario) references propietario(id_propietario)
	on delete restrict
	on update cascade,
	
	constraint fk_id_raza foreign key(id_raza) references raza(id_raza)
	on delete restrict
	on update cascade
);

------------------------------------------------------------------------------

create table especialidad(
	id_especialidad bigint generated always as identity, --pk
	
	nombre varchar(255) not null, --uq
	descripcion text,
	
	constraint pk_id_especialidad primary key(id_especialidad),
	constraint uq_nombre_especialidad unique(nombre)
);


create table veterinario(
	id_veterinario bigint generated always as identity, --pk
	
	DUI varchar(10) not null, -- uq
	nombre varchar(255) not null,
	apellidos varchar(255) not null,
	telefono varchar(15),
	email varchar(255), --uq, ck
	direccion varchar(255),
	cedula_profesional varchar(255) not null, --uq
	salario numeric(8,2), --ck
	fecha_nacimiento_veterinario date, --ck
	
	id_especialidad bigint not null, --fk
	
	constraint pk_id_veterinario primary key(id_veterinario),
	constraint uq_DUI_veterinario unique(DUI),
	constraint uq_email_veterinario unique(email),
	constraint ck_email_veterinario check(email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
	constraint ck_salario check(salario >= 0),
	constraint uq_cedula_profesional unique(cedula_profesional),
	
	constraint fk_id_especialidad foreign key(id_especialidad) references especialidad(id_especialidad)
	on delete restrict
	on update cascade
);


create table consulta(
	id_consulta bigint generated always as identity, --pk
	id_mascota bigint not null, --fk
	id_veterinario bigint not null, --fk
	
	costo_consulta numeric(10,2) not null, --ck
	descripcion text,
	motivo varchar(255) not null,
	estado varchar(15) not null, --ck
	
	fecha_hora_inicio timestamp not null, -- ck
	fecha_hora_finalizar timestamp,
	
	constraint pk_id_consulta primary key(id_consulta),
	constraint ck_costo_consulta check(costo_consulta > 0),
	constraint ck_estado check(estado in ('Pendiente','En proceso','Finalizada','Cancelada')),
	constraint ck_fecha_hora_inicio check(fecha_hora_finalizar is null or fecha_hora_finalizar >= fecha_hora_inicio),
	constraint ck_fecha_logica check(fecha_hora_inicio >= '2020-01-01 00:00:00'),
	
	constraint fk_id_mascota foreign key(id_mascota) references mascota(id_mascota)
	on delete restrict
	on update cascade,
	
	constraint fk_id_veterinario foreign key(id_veterinario) references veterinario(id_veterinario)
	on delete restrict
	on update cascade
);

---------------------------------------------------------------------------------

create table factura(
	id_factura bigint generated always as identity, --pk
	id_consulta bigint not null, --fk -- uq
	
	total_a_pagar numeric(10,2) not null, --ck
	metodo_pago varchar(20) not null, --ck
	fecha_de_emision date default current_date,
	
	constraint pk_id_factura primary key(id_factura),
	constraint uq_id_consulta unique(id_consulta),
	constraint ck_total_a_pagar check(total_a_pagar > 0),
	constraint ck_metodo_pago check(metodo_pago in ('Efectivo','Tarjeta','Transferencia')),
	
	constraint fk_id_consulta foreign key(id_consulta) references consulta(id_consulta)
	on delete restrict
	on update cascade
);


create table detalle_factura(
	id_detalle_factura bigint generated always as identity, --pk
	id_factura bigint not null, --fk
	
	tipo_concepto varchar(20) not null,
	concepto varchar(255) not null, --ck
	cantidad int not null, --ck
	precio_unitario numeric(10,2) not null, --ck
	subtotal numeric(10,2) generated always as (cantidad * precio_unitario) stored,
	-- esto permite que se calcule el subtotal directamente y con el uso de stored se guarde en la tabla
	
	constraint pk_id_detalle_factura primary key(id_detalle_factura),
	constraint ck_concepto check(concepto in ('Consulta','Medicamento','Vacuna','Procedimiento','Otro')),
	constraint ck_cantidad check(cantidad > 0),
	constraint ck_precio_unitario check(precio_unitario > 0),
	
	constraint fk_id_factura foreign key(id_factura) references factura(id_factura)
	on delete restrict
	on update cascade
);

-------------------------------------------------------------------------------------

create table medicamento(
	id_medicamento bigint generated always as identity, --pk
	
	nombre varchar(255) not null,
	marca varchar(255),
	componentes text,
	costo_unitario numeric(6,2) not null, --ck
	fecha_caducidad date, --ck
	
	constraint pk_id_medicamento primary key(id_medicamento),
	constraint ck_costo_unitario check(costo_unitario > 0),
	constraint ck_fecha_caducidad check(fecha_caducidad is null or fecha_caducidad >= current_date)
);


create table mascota_alergia(
	id_mascota bigint, --pk, fk
	id_medicamento bigint, --pk, fk
	
	severidad varchar(15), --ck
	reaccion text,
	fecha_deteccion date not null default current_date,
	
	constraint pk_mascota_alergia primary key(id_mascota, id_medicamento),
	constraint ck_severidad check(severidad in ('Critico','Grave','Moderado','Leve')),
	
	constraint fk_id_mascota foreign key(id_mascota) references mascota(id_mascota)
	on delete restrict
	on update cascade,
	
	constraint fk_id_medicamento foreign key(id_medicamento) references medicamento(id_medicamento)
	on delete restrict
	on update cascade
);


----------------------------------------------------------------------------

create table diagnostico(
	id_diagnostico bigint generated always as identity, --pk
	id_consulta bigint not null, --fk
	
	detalle text not null,
	gravedad varchar(20) not null, --ck
	fecha_emision date default current_date,
	
	constraint pk_id_diagnostico primary key(id_diagnostico),
	constraint ck_gravedad check(gravedad in ('Critico','Grave','Moderado','Leve')),
	
	constraint fk_id_consulta foreign key(id_consulta) references consulta(id_consulta)
	on delete restrict
	on update cascade
);


create table procedimiento(
	id_procedimiento bigint generated always as identity, --pk
	
	nombre varchar(255) not null, --uq
	detalles text,
	costo numeric(7,2) not null, --ck
	
	constraint pk_id_procedimiento primary key(id_procedimiento),
	constraint uq_nombre_procedimiento unique(nombre),
	constraint ck_costo_procedimiento check(costo > 0)
);


create table procedimiento_diagnostico(
	id_diagnostico bigint, --pk, fk
	id_procedimiento bigint, --pk, fk
	
	observaciones text,
	fecha_programada date,
	precio_historico numeric(7,2) not null, --ck
	
	constraint pk_procedimiento_diagnostico primary key(id_diagnostico, id_procedimiento),
	constraint ck_precio_historico check(precio_historico > 0),
	
	constraint fk_id_diagnostico foreign key(id_diagnostico) references diagnostico(id_diagnostico)
	on delete restrict
	on update cascade,
	
	constraint fk_id_procedimiento foreign key(id_procedimiento) references procedimiento(id_procedimiento)
	on delete restrict
	on update cascade
);


------------------------------------------------------------

create table tratamiento(
	id_tratamiento bigint generated always as identity, --pk
	id_diagnostico bigint not null, --fk
	
	duracion varchar(255),
	detalle text not null,
	fecha_inicio date not null default current_date,
	
	constraint pk_id_tratamiento primary key(id_tratamiento),
	
	constraint fk_id_diagnostico foreign key(id_diagnostico) references diagnostico(id_diagnostico)
	on delete restrict
	on update cascade
);


create table tratamiento_medicamento(
	id_tratamiento bigint, --pk, fk
	id_medicamento bigint, --pk, fk
	
	dosis varchar(255) not null,
	frecuencia varchar(50) not null,
	indicaciones text,
	cantidad_prescrita int not null, --ck
	precio_historico numeric(7,2) not null, --ck
	
	constraint pk_tratamiento_medicamento primary key(id_tratamiento, id_medicamento),
	constraint ck_cantidad_prescrita check(cantidad_prescrita > 0),
	constraint ck_precio_historico check(precio_historico > 0),
	
	constraint fk_id_tratamiento foreign key(id_tratamiento) references tratamiento(id_tratamiento)
	on delete restrict
	on update cascade,
	
	constraint fk_id_medicamento foreign key(id_medicamento) references medicamento(id_medicamento)
	on delete restrict
	on update cascade
);