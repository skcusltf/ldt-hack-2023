-- +goose Up
-- +goose StatementBegin
create type person_sex as enum ('male', 'female');

create table business_user (
  id bigserial primary key,
  account_id bigint references account (id), -- nullable to allow account deletion
  first_name text not null,
  patronymic_name text not null,
  last_name text not null,
  sex person_sex not null,
  birth_date date not null,
  business_name text not null
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table business_user;
drop type person_sex;
-- +goose StatementEnd
