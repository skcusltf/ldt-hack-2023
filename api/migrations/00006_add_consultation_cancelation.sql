-- +goose Up
-- +goose StatementBegin
-- Recreate index over only non-canceled appointments
alter table consultation_appointment drop constraint consultation_appointment_slot_id_inspector_user_id_key;
alter table consultation_appointment add column canceled_at timestamptz;
create unique index consultation_appointment_slot_id_inspector_user_id_key on consultation_appointment (slot_id, inspector_user_id) where (canceled_at is null);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
drop index consultation_appointment_slot_id_inspector_user_id_key;
alter table consultation_appointment drop column canceled_at;
alter table consultation_appointment add constraint consultation_appointment_slot_id_inspector_user_id_key unique (slot_id, inspector_user_id);
-- +goose StatementEnd
