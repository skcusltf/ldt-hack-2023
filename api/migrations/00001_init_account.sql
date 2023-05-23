-- +goose Up
-- +goose StatementBegin
create type account_type as enum ('business', 'authority');

create table account (
  id bigserial primary key,
  type account_type not null,
  email text unique not null,
  password_hash bytea not null
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table account;
drop type account_type;
-- +goose StatementEnd
