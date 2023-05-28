-- +goose Up
-- +goose StatementBegin
create extension if not exists "uuid-ossp";

create table consultation_appointments (
  id uuid primary key default gen_random_uuid(),
  topic_id bigint references authority_consultation_topic (id),
  slot_id bigint references authority_consultation_slots (id),
  business_user_id bigint references business_user (id),
  inspector_user_id bigint references inspector_user (id),
  unique (slot_id, inspector_user_id)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table consultation_appointments;
-- +goose StatementEnd
