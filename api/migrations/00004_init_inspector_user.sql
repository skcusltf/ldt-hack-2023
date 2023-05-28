-- +goose Up
-- +goose StatementBegin
create table inspector_user (
  id bigserial primary key,
  account_id bigint references account (id), -- nullable to allow account deletion
  authority_id bigint references authority (id),
  first_name text not null,
  last_name text not null
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table inspector_user;
-- +goose StatementEnd
