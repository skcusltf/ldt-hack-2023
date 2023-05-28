-- +goose Up
-- +goose StatementBegin
create table authority (
  id bigserial primary key,
  name text unique not null
);

create table authority_consultation_topic (
  id bigserial primary key,
  authority_id bigint references authority (id),
  name text not null,
  unique (authority_id, name)
);

create table authority_consultation_slots (
  id bigserial primary key,
  authority_id bigint references authority (id),
  from_time timestamptz not null,
  to_time timestamptz not null,
  unique (authority_id, from_time, to_time)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table authority_consultation_slots;
drop table authority_consultation_topic;
drop table authority;
-- +goose StatementEnd
