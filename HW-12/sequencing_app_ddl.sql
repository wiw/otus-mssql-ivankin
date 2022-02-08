create database seqapp;
GO

use seqapp;
GO

create schema Dictionaries;
GO

create schema Sequencing;
GO

create schema Personalities;
GO

create schema Geography;
GO

create schema Warehouse;
GO

create table Dictionaries.street_types
(
    street_type_id   int          not null identity (1, 1) primary key,
    street_type_name varchar(255) not null,
);

create table Dictionaries.city_types
(
    city_type_id   int          not null identity (1, 1) primary key,
    city_type_name varchar(255) not null,
);

create table Dictionaries.part_dictionary
(
    part_dictionary_id int           not null identity (1, 1) primary key,
    part_name          varchar(2048) not null,
    part_type          varchar(255)  not null,
);

create table Dictionaries.sequencing_programs
(
    sequencing_program_id int           not null identity (1, 1) primary key,
    program_name          varchar(2048) not null,
    duration              int           not null,
);

create table Geography.countries
(
    country_id   int          not null identity (1, 1) primary key,
    country_name varchar(255) not null,
    country_code varchar(8)   not null,
);

create table Geography.regions
(
    region_id       int          not null identity (1, 1) primary key,
    country_id      int foreign key references Geography.countries (country_id),
    region_name     varchar(255) not null,
    region_code     varchar(8)   not null,
    region_kladr_id varchar(128) not null,
);

create table Geography.cities
(
    city_id   int          not null identity (1, 1) primary key,
    region_id int foreign key references Geography.regions (region_id),
    city_type int foreign key references Dictionaries.city_types (city_type_id),
    city_name varchar(255) not null,
);

create table Geography.streets
(
    street_id   int          not null identity (1, 1) primary key,
    street_type int foreign key references Dictionaries.street_types (street_type_id),
    city_id     int foreign key references Geography.cities (city_id),
    street_name varchar(255) not null,
);

create table Geography.house
(
    house_id     int         not null identity (1, 1) primary key,
    city_id      int foreign key references Geography.cities (city_id),
    street_id    int foreign key references Geography.streets (street_id),
    house_number varchar(32) not null,
);

create table Personalities.address
(
    address_id int not null identity (1, 1) primary key,
    country_id int foreign key references Geography.countries (country_id),
    region_id  int foreign key references Geography.regions (region_id),
    city_id    int foreign key references Geography.cities (city_id),
    street_id  int foreign key references Geography.streets (street_id),
    house_id   int foreign key references Geography.house (house_id),
);

create table Personalities.location_address
(
    location_address_id int not null identity (1, 1) primary key,
    address_id          int foreign key references Personalities.address (address_id),
    floor               int null,
    room                int null
);

create table Personalities.persons
(
    person_id           int          not null identity (1, 1) primary key,
    first_name          varchar(255) not null,
    second_name         varchar(255) null,
    last_name           varchar(255) not null,
    mobile_phone_number bigint       null,
    email               varchar(512) not null
);

create table Personalities.organizations
(
    organization_id   int           not null identity (1, 1) primary key,
    organization_name varchar(2048) not null,
    address_id        int foreign key references Personalities.address (address_id)
);

create table Personalities.customers
(
    customer_id      int not null identity (1, 1) primary key,
    person_id        int foreign key references Personalities.persons (person_id),
    organization_id  int null foreign key references Personalities.organizations (organization_id),
    location_address int foreign key references Personalities.location_address (location_address_id),
);


create table Personalities.executors
(
    executor_id      int not null identity (1, 1) primary key,
    person_id        int foreign key references Personalities.persons (person_id),
    organization_id  int null foreign key references Personalities.organizations (organization_id),
    location_address int foreign key references Personalities.location_address (location_address_id)
);

create table Warehouse.equipment
(

    equipment_id   int          not null identity (1, 1) primary key,
    equipment_name varchar(512) not null,
);

create table Warehouse.warehouses
(

    warehouses_id       int          not null identity (1, 1) primary key,
    warehouse_name      varchar(512) null,
    location_address_id int foreign key references Personalities.location_address (location_address_id),
);

create table Warehouse.parts
(
    part_id                   int          not null identity (1, 1) primary key,
    part_dictionary_id        int foreign key references Dictionaries.part_dictionary (part_dictionary_id),
    inventory_id              varchar(512) not null,
    cycles_before_replacement int          not null,
);

create table Warehouse.sub_part_stocks
(

    sub_part_stocks_id       int not null identity (1, 1) primary key,
    part_dictionary_id       int not null foreign key references Dictionaries.part_dictionary (part_dictionary_id),
    part_id                  int foreign key references Warehouse.parts (part_id),
    sub_part_stocks_quantity int not null,
    warehouses_id            int foreign key references Warehouse.warehouses (warehouses_id),
);

create table Warehouse.stock
(

    stock_id        int      not null identity (1, 1) primary key,
    part_id         int foreign key references Warehouse.parts (part_id),
    part_quantity   int      not null,
    warehouses_id   int foreign key references Warehouse.warehouses (warehouses_id),
    coming_datetime datetime not null,
);

create table Warehouse.parts_on_equipment
(

    parts_on_equipment_id int                                                              not null identity (1, 1) primary key,
    equipment_id          int foreign key references Warehouse.equipment (equipment_id),
    part_id               int foreign key references Warehouse.parts (part_id),
    is_sub_part           bit                                                              not null default 1,
    installed_datetime    datetime                                                         not null,
    who_installed         int foreign key references Personalities.executors (executor_id) null,
);

create table Warehouse.movements_history
(
    movements_history_id int                                                                       not null identity (1, 1) primary key,
    part_id              int foreign key references Warehouse.parts (part_id),
    sub_part_stocks_id   int foreign key references Warehouse.sub_part_stocks (sub_part_stocks_id) null,
    warehouses_id        int foreign key references Warehouse.warehouses (warehouses_id)           null,
    equipment_id         int foreign key references Warehouse.equipment (equipment_id)             null,
    movement_datetime    datetime                                                                  not null,
    who_moved            int foreign key references Personalities.executors (executor_id)          null,
);


create table Sequencing.orders
(
    order_id        int        not null identity (1, 1) primary key,
    unique_order_id varchar(8) not null,
    customer_id     int foreign key references Personalities.customers (customer_id),
    order_datetime  datetime   not null,
);

create table Sequencing.order_list
(
    order_list_id         int           not null identity (1, 1) primary key,
    order_id              int foreign key references Sequencing.orders (order_id),
    sequencing_program_id int foreign key references Dictionaries.sequencing_programs (sequencing_program_id),
    sample_serial         int           not null,
    sample_name           varchar(2048) not null,
    sample_description    varchar(2048) null,
    coming_datetime       datetime      not null,
);

create table Sequencing.execution_orders
(
    execution_order_id int      not null identity (1, 1) primary key,
    executor_id        int foreign key references Personalities.executors (executor_id),
    order_id           int foreign key references Sequencing.orders (order_id),
    execution_datetime datetime not null,
    equipment_id       int foreign key references Warehouse.equipment (equipment_id),
);

create table Sequencing.plates
(
    plate_id     int         not null identity (1, 1) primary key,
    plate_serial varchar(16) not null,
    part_id      int foreign key references Warehouse.parts (part_id),
    free_holes   int         not null default 96,
    is_new       bit         not null default 1,
);

create table Sequencing.execution_order_list
(
    execution_order_list_id int      not null identity (1, 1) primary key,
    execution_order_id      int foreign key references Sequencing.execution_orders (execution_order_id),
    plate_id                int foreign key references Sequencing.plates (plate_id),
    order_list_id           int foreign key references Sequencing.order_list (order_list_id),
    hole_coord_x            char(1)  not null,
    hole_coord_y            tinyint  not null,
    start_datetime          datetime not null,
    end_datetime            datetime not null,
);

create table Sequencing.sequencing_result
(
    sequencing_result_id int           not null identity (1, 1) primary key,
    execution_order_list int foreign key references Sequencing.execution_order_list (execution_order_list_id),
    result_path          varchar(1024) not null,
);
