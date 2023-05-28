package storage

import (
	"context"
	"database/sql"
	"errors"
	"math/rand"
	"time"

	"github.com/uptrace/bun"
)

var ErrConsultationSlotExhausted = errors.New("chosen consultation slot has already been taken")

type ConsultationTopic struct {
	bun.BaseModel `bun:"table:authority_consultation_topic"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64     `bun:"type:bigint"`
	Authority   Authority `bun:"rel:belongs-to,join:authority_id=id"`
	Name        string    `bun:"type:text,notnull"`
}

type ConsultationSlot struct {
	bun.BaseModel `bun:"table:authority_consultation_slots,alias:acs"`

	ID          int64     `bun:",pk,type:bigserial,autoincrement"`
	AuthorityID int64     `bun:"type:bigint"`
	Authority   Authority `bun:"rel:belongs-to,join:authority_id=id"`
	FromTime    time.Time `bun:"type:timestamptz,notnull"`
	ToTime      time.Time `bun:"type:timestamptz,notnull"`
}

type ConsultationAppointment struct {
	bun.BaseModel `bun:"table:consultation_appointment,alias:ca"`

	ID              string            `bun:",pk,type:uuid,default:uuid_generate_v4()"`
	TopicID         int64             `bun:"type:bigint"`
	Topic           ConsultationTopic `bun:"rel:belongs-to,join:topic_id=id"`
	SlotID          int64             `bun:"type:bigint"`
	Slot            ConsultationSlot  `bun:"rel:belongs-to,join:slot_id=id"`
	BusinessUserID  int64             `bun:"type:bigint"`
	BusinessUser    BusinessUser      `bun:"rel:belongs-to,join:business_user_id=id"`
	InspectorUserID int64             `bun:"type:bigint"`
	InspectorUser   InspectorUser     `bun:"rel:belongs-to,join:inspector_user_id=id"`
}

// CreateTopicsTx creates topics which don't exist yet and returns all of the topics in the DB.
func (db *Database) CreateTopicsTx(ctx context.Context, tx bun.Tx, topics []ConsultationTopic) error {
	// Insert new ones
	if _, err := tx.NewInsert().Model(&topics).On("conflict do nothing").Exec(ctx); err != nil {
		return wrapError("CreateTopicsTx.Insert", err)
	}

	return nil
}

// CreateSlotsTx creates consultation slots which don't exist yet.
func (db *Database) CreateSlotsTx(ctx context.Context, tx bun.Tx, slots []ConsultationSlot) error {
	if _, err := tx.NewInsert().Model(&slots).On("conflict do nothing").Exec(ctx); err != nil {
		return wrapError("CreateSlotsTx", err)
	}

	return nil
}

// CreateConsultationAppointment creates a new consultation appointment for the specified business user
// with a random available inspector of the specified authority.
func (db *Database) CreateConsultationAppointment(ctx context.Context, topicID, slotID, businessUserID int64) (InspectorUser, error) {
	var chosenInspector InspectorUser

	err := db.bun.RunInTx(ctx, &sql.TxOptions{
		ReadOnly: false,
	}, func(ctx context.Context, tx bun.Tx) error {
		var availableInspectors []InspectorUser
		err := tx.NewSelect().Model(&availableInspectors).
			Join("join authority_consultation_slots acs on acs.authority_id = iu.authority_id").
			Join("left join consultation_appointment ca on ca.slot_id = acs.id and ca.inspector_user_id = iu.id").
			Where("acs.id = ?", slotID).
			Where("ca.id is null").
			Scan(ctx)
		if err != nil {
			return wrapError("Inspectors", err)
		} else if len(availableInspectors) == 0 {
			return ErrConsultationSlotExhausted
		}

		chosenInspector = availableInspectors[rand.Intn(len(availableInspectors))]
		appointment := ConsultationAppointment{
			TopicID:         topicID,
			SlotID:          slotID,
			BusinessUserID:  businessUserID,
			InspectorUserID: chosenInspector.ID,
		}

		if _, err := tx.NewInsert().Model(&appointment).Returning("").Exec(ctx); err != nil {
			return wrapError("Insert", err)
		}

		return nil
	})
	if err != nil {
		return InspectorUser{}, wrapError("CreateConsultationAppointment", err)
	}

	return chosenInspector, nil
}

// ListConsultationTopics returns a list of all of the consultation topics.
func (db *Database) ListConsultationTopics(ctx context.Context) ([]ConsultationTopic, error) {
	var topics []ConsultationTopic

	if err := db.bun.NewSelect().Model(&topics).Relation("Authority").Scan(ctx); err != nil {
		return nil, wrapError("ListConsultationTopics", err)
	}

	return topics, nil
}

// ListConsultationSlots returns a list of available dates for the specified authority and date range.
func (db *Database) ListAvailableConsultationDates(ctx context.Context, authorityID int64, from_date, to_date time.Time,
) ([]time.Time, error) {
	var dates []time.Time

	// Select all consultation slots join with inspectors for the specified authority
	// where a consultation appointment for the given inspector and slot does not exist.
	err := db.bun.NewSelect().Model((*ConsultationSlot)(nil)).
		Column("acs.from_time").
		Join("join inspector_user iu on iu.authority_id = acs.authority_id").
		Join("left join consultation_appointment ca on ca.slot_id = acs.id and ca.inspector_user_id = iu.id").
		Where("acs.authority_id = ?", authorityID).
		Where("acs.from_time::date >= ?::date", from_date).
		Where("acs.to_time::date <= ?::date", to_date).
		Where("ca.id is null").
		Scan(ctx, &dates)
	if err != nil {
		return nil, wrapError("ListAvailableConsultationDates", err)
	}

	return dates, nil
}

// ListAvailableConsultationSlots returns a list of available consultation slots for the specified authority and date.
func (db *Database) ListAvailableConsultationSlots(ctx context.Context, authorityID int64, date time.Time,
) ([]ConsultationSlot, error) {
	var slots []ConsultationSlot

	// Like the query in ListAvailableConsultationDates but filters based on specific date instead of range
	err := db.bun.NewSelect().Model(&slots).
		Join("join inspector_user iu on iu.authority_id = acs.authority_id").
		Join("left join consultation_appointment ca on ca.slot_id = acs.id and ca.inspector_user_id = iu.id").
		Where("acs.authority_id = ?", authorityID).
		Where("acs.from_time::date = ?::date", date).
		Where("ca.id is null").
		Scan(ctx)
	if err != nil {
		return nil, wrapError("ListAvailableConsultationSlots", err)
	}

	return slots, nil
}

// ListBusinessConsultationAppointments lists consultation appointments for a business user.
// This includes only the appointments which the user have created themselves.
func (db *Database) ListBusinessConsultationAppointments(ctx context.Context, accountID int64,
) ([]ConsultationAppointment, error) {
	var appointments []ConsultationAppointment

	selectBusinessUserID := db.bun.NewSelect().Model((*BusinessUser)(nil)).
		Column("id").
		Where("account_id = ?", accountID)

	err := db.bun.NewSelect().Model(&appointments).
		Column("ca.id").
		ColumnExpr("authority.name as inspector_user__authority__name").
		Relation("Topic").
		Relation("Slot").
		Relation("BusinessUser").
		Relation("InspectorUser").
		Join("left join authority on inspector_user.authority_id = authority.id").
		Where("ca.business_user_id = (?)", selectBusinessUserID).
		Order("slot.from_time").
		Scan(ctx)
	if err != nil {
		return nil, wrapError("ListBusinessConsultationAppointments", err)
	}

	return appointments, nil
}

// ListInspectorConsultationAppointments lists consultation appointments for an authority inspector.
// This includes the appointments which have been created by the business users.
func (db *Database) ListInspectorConsultationAppointments(ctx context.Context, accountID int64,
) ([]ConsultationAppointment, error) {
	var appointments []ConsultationAppointment

	selectInspectorUserID := db.bun.NewSelect().Model((*InspectorUser)(nil)).
		Column("id").
		Where("account_id = ?", accountID)

	err := db.bun.NewSelect().Model(&appointments).
		Column("ca.id").
		ColumnExpr("authority.name as inspector_user__authority__name").
		Relation("Topic").
		Relation("Slot").
		Relation("BusinessUser").
		Relation("InspectorUser").
		Join("left join authority on inspector_user.authority_id = authority.id").
		Where("ca.inspector_user_id = (?)", selectInspectorUserID).
		Order("slot.from_time").
		Scan(ctx)
	if err != nil {
		return nil, wrapError("ListInspectorConsultationAppointments", err)
	}

	return appointments, nil
}
