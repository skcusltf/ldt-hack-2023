-- +goose Up
-- +goose StatementBegin
create table chat_message (
  id bigserial primary key,
  request text not null,
  response text[] not null,
  rating boolean
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table chat_message;
-- +goose StatementEnd
