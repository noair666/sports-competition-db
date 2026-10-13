-- ============================================================================
-- База данных: sports_competition_db
-- Даталогическая модель: «Спортивные соревнования и инфраструктура»
-- Назначение: хранение справочников, расписания, участников, результатов и судейства
-- ============================================================================

-- Таблица: cities (справочник городов)
-- Назначение: список городов, где проводятся мероприятия и базируются организации
CREATE TABLE cities (
    city_id    SERIAL PRIMARY KEY,           -- Уникальный идентификатор города
    name       VARCHAR(100) NOT NULL         -- Название города
);

-- Таблица: sports_types (виды спорта)
-- Назначение: классификация по видам спорта (например, «лёгкая атлетика», «плавание»)
CREATE TABLE sports_types (
    sport_type_id  SERIAL PRIMARY KEY,       -- Уникальный идентификатор вида спорта
    name           VARCHAR(100) NOT NULL     -- Название вида спорта
);

-- Таблица: disciplines (дисциплины)
-- Назначение: дисциплины внутри вида спорта (например, «бег на 100 м», «прыжки в длину»)
CREATE TABLE disciplines (
    discipline_id   SERIAL PRIMARY KEY,      -- Уникальный идентификатор дисциплины
    name            VARCHAR(100) NOT NULL,   -- Название дисциплины
    sport_type_id   INT NOT NULL,            -- Ссылка на вид спорта
    CONSTRAINT fk_disciplines_sport_type
        FOREIGN KEY (sport_type_id)
        REFERENCES sports_types(sport_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT -- Запрет удаления вида спорта, если есть дисциплины
);

-- Таблица: venues (спортивные объекты)
-- Назначение: спортивные площадки, стадионы, бассейны и т. п.
CREATE TABLE venues (
    venue_id   SERIAL PRIMARY KEY,           -- Уникальный идентификатор объекта
    name       VARCHAR(100) NOT NULL,         -- Название объекта
    city_id    INT NOT NULL,                 -- Город расположения
    capacity   INT,                          -- Вместимость (может быть NULL, если неизвестно)
    CONSTRAINT fk_venues_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Таблица: sports_organizations (спортивные организации)
-- Назначение: клубы, федерации, школы, представляющие участников
CREATE TABLE sports_organizations (
    organization_id  SERIAL PRIMARY KEY,      -- Уникальный идентификатор организации
    name             VARCHAR(100) NOT NULL,   -- Название организации
    city_id          INT NOT NULL,            -- Город базирования
    type             VARCHAR(50),             -- Тип организации (клуб, федерация, школа и т. п.)
    CONSTRAINT fk_organizations_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Таблица: participants (участники)
-- Назначение: спортсмены, выступающие на соревнованиях
CREATE TABLE participants (
    participant_id   SERIAL PRIMARY KEY,      -- Уникальный идентификатор участника
    full_name        VARCHAR(100) NOT NULL,   -- ФИО спортсмена
    birth_date       DATE,                    -- Дата рождения
    gender           CHAR(1) CHECK (gender IN ('M', 'F')), -- Пол: M (male), F (female)
    organization_id  INT NOT NULL,            -- Принадлежность к организации
    CONSTRAINT fk_participants_organization
        FOREIGN KEY (organization_id)
        REFERENCES sports_organizations(organization_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Таблица: competitions (соревнования)
-- Назначение: основные сведения о соревновании (название, даты, город, статус)
CREATE TABLE competitions (
    competition_id  SERIAL PRIMARY KEY,       -- Уникальный идентификатор соревнования
    name            VARCHAR(150) NOT NULL,    -- Название соревнования
    start_date      DATE NOT NULL,            -- Дата начала
    end_date        DATE NOT NULL,            -- Дата окончания
    city_id         INT NOT NULL,             -- Город проведения
    status          VARCHAR(20) DEFAULT 'planned', -- Статус: planned, ongoing, completed
    CONSTRAINT fk_competitions_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_dates
        CHECK (end_date >= start_date)        -- Проверка корректности дат
);

-- Таблица: competition_venues (расписание использования объектов)
-- Назначение: привязка соревнований к конкретным объектам и временным слотам
CREATE TABLE competition_venues (
    competition_id  INT NOT NULL,             -- Ссылка на соревнование
    venue_id        INT NOT NULL,             -- Ссылка на объект
    start_time      TIMESTAMP NOT NULL,       -- Время начала использования
    end_time        TIMESTAMP NOT NULL,       -- Время окончания использования
    PRIMARY KEY (competition_id, venue_id),   -- Составной первичный ключ
    CONSTRAINT fk_comp_ven_competition
        FOREIGN KEY (competition_id)
        REFERENCES competitions(competition_id)
        ON UPDATE CASCADE ON DELETE CASCADE,   -- При удалении соревнования удаляются все привязки
    CONSTRAINT fk_comp_ven_venue
        FOREIGN KEY (venue_id)
        REFERENCES venues(venue_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_times
        CHECK (end_time > start_time)          -- Проверка корректности временных интервалов
);

-- Таблица: results (результаты выступлений)
-- Назначение: фиксация результатов участников по дисциплинам
CREATE TABLE results (
    result_id       SERIAL PRIMARY KEY,       -- Уникальный идентификатор результата
    competition_id  INT NOT NULL,             -- Ссылка на соревнование
    discipline_id   INT NOT NULL,             -- Ссылка на дисциплину
    participant_id  INT NOT NULL,             -- Ссылка на участника
    place           INT,                      -- Занятое место (может быть NULL, если нет мест)
    result_value    VARCHAR(50),              -- Значение результата (время, метры, очки и т. п.)
    date            DATE NOT NULL,            -- Дата выступления
    CONSTRAINT fk_results_competition
        FOREIGN KEY (competition_id)
        REFERENCES competitions(competition_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_results_discipline
        FOREIGN KEY (discipline_id)
        REFERENCES disciplines(discipline_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_results_participant
        FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_place
        CHECK (place IS NULL OR place > 0)     -- Место должно быть положительным либо отсутствовать
);

-- Таблица: referee_roles (роли судей)
-- Назначение: справочник ролей (главный судья, судья на линии, хронометрист и т. п.)
CREATE TABLE referee_roles (
    role_id  SERIAL PRIMARY KEY,              -- Уникальный идентификатор роли
    name     VARCHAR(50) NOT NULL             -- Название роли
);

-- Таблица: referees (судьи)
-- Назначение: сведения о судьях и их принадлежности к организациям
CREATE TABLE referees (
    referee_id      SERIAL PRIMARY KEY,       -- Уникальный идентификатор судьи
    full_name       VARCHAR(100) NOT NULL,    -- ФИО судьи
    category        VARCHAR(50),              -- Категория/разряд судьи
    organization_id INT NOT NULL,             -- Принадлежность к организации
    CONSTRAINT fk_referees_organization
        FOREIGN KEY (organization_id)
        REFERENCES sports_organizations(organization_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Таблица: referee_assignments (назначения судей)
-- Назначение: распределение судей по соревнованиям, дисциплинам и ролям
CREATE TABLE referee_assignments (
    assignment_id    SERIAL PRIMARY KEY,       -- Уникальный идентификатор назначения
    competition_id   INT NOT NULL,            -- Ссылка на соревнование
    discipline_id    INT NOT NULL,            -- Ссылка на дисциплину
    referee_id       INT NOT NULL,            -- Ссылка на судью
    role_id          INT NOT NULL,            -- Ссылка на роль
    CONSTRAINT fk_assign_competition
        FOREIGN KEY (competition_id)
        REFERENCES competitions(competition_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_assign_discipline
        FOREIGN KEY (discipline_id)
        REFERENCES disciplines(discipline_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_assign_referee
        FOREIGN KEY (referee_id)
        REFERENCES referees(referee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_assign_role
        FOREIGN KEY (role_id)
        REFERENCES referee_roles(role_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);
