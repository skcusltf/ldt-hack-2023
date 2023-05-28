-- +goose Up
-- +goose StatementBegin
create extension if not exists "uuid-ossp";

create table consultation_appointment (
  id uuid primary key default gen_random_uuid(),
  topic_id bigint not null references authority_consultation_topic (id),
  slot_id bigint not null references authority_consultation_slots (id),
  business_user_id bigint not null references business_user (id),
  inspector_user_id bigint not null references inspector_user (id),
  unique (slot_id, inspector_user_id)
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop table consultation_appointments;
-- +goose StatementEnd
