package app

import (
	"context"
	"errors"
	"sort"
	"time"

	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"github.com/samber/lo"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var (
	errSlotAlreadyTaken     = status.Error(codes.AlreadyExists, "Выбранное время консультации уже занял другой человек, выберите новое!")
	errConsultationNotFound = status.Error(codes.NotFound, "Выбрана несуществующая консультация")
)

// ListConsultationTopics implements the consultation topic listing endpoint.
func (s *Service) ListConsultationTopics(ctx context.Context, _ *emptypb.Empty) (*desc.ListConsultationTopicsResponse, error) {
	if _, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness); !authorized {
		return nil, errUnauthorized
	}

	topics, err := s.db.ListConsultationTopics(ctx)
	if err != nil {
		s.logger.Error("failed to list consultation topics", "error", err)
		return nil, errInternal
	}

	topicsByAuthority := lo.GroupBy(topics, func(topic storage.ConsultationTopic) string {
		return topic.Authority.Name
	})

	responseTopics := lo.MapToSlice(topicsByAuthority, func(authority string, topics []storage.ConsultationTopic,
	) *desc.ListConsultationTopicsResponse_AuthorityTopics {
		return &desc.ListConsultationTopicsResponse_AuthorityTopics{
			AuthorityId:   topics[0].Authority.ID,
			AuthorityName: topics[0].Authority.Name,
			Topics: lo.Map(topics, func(topic storage.ConsultationTopic, _ int,
			) *desc.ListConsultationTopicsResponse_AuthorityTopic {
				return &desc.ListConsultationTopicsResponse_AuthorityTopic{
					TopicId:   topic.ID,
					TopicName: topic.Name,
				}
			}),
		}
	})

	// Always maintain a single ordering
	sort.Slice(responseTopics, func(i, j int) bool {
		return responseTopics[i].AuthorityName < responseTopics[j].AuthorityName
	})

	return &desc.ListConsultationTopicsResponse{
		AuthorityTopics: responseTopics,
	}, nil
}

// ListAvailableConsultationSlots implements the available consultation dates listing endpoint.
func (s *Service) ListAvailableConsultationDates(ctx context.Context, req *desc.ListAvailableConsultationDatesRequest) (*desc.ListAvailableConsultationDatesResponse, error) {
	if _, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness); !authorized {
		return nil, errUnauthorized
	}

	dates, err := s.db.ListAvailableConsultationDates(ctx, req.AuthorityId, req.FromDate.AsTime(), req.ToDate.AsTime())
	if err != nil {
		s.logger.Error("failed to list available consultation slots",
			"authority_id", req.AuthorityId,
			"from_date", req.FromDate.AsTime(),
			"to_date", req.ToDate.AsTime(),
			"error", err,
		)

		return nil, errInternal
	}

	// Uniquefy slots by their date
	dates = lo.UniqBy(dates, func(date time.Time) int64 {
		return time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location()).UnixNano()
	})

	// Sort dates to keep an ordering in the responses
	sort.Slice(dates, func(i, j int) bool {
		return dates[i].Before(dates[j])
	})

	return &desc.ListAvailableConsultationDatesResponse{
		AvailableDates: lo.Map(dates, func(date time.Time, _ int) *timestamppb.Timestamp {
			return timestamppb.New(date)
		}),
	}, nil
}

// ListAvailableConsultationSlots implements the available consultation slots listing endpoint.
func (s *Service) ListAvailableConsultationSlots(ctx context.Context, req *desc.ListAvailableConsultationSlotsRequest) (*desc.ListAvailableConsultationSlotsResponse, error) {
	if _, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness); !authorized {
		return nil, errUnauthorized
	}

	slots, err := s.db.ListAvailableConsultationSlots(ctx, req.AuthorityId, req.Date.AsTime())
	if err != nil {
		s.logger.Error("failed to list available consultation slots",
			"authority_id", req.AuthorityId,
			"date", req.Date.AsTime(),
			"error", err,
		)

		return nil, errInternal
	}

	// Sort slots to keep an ordering in the responses
	sort.Slice(slots, func(i, j int) bool {
		return slots[i].FromTime.Before(slots[j].FromTime)
	})

	return &desc.ListAvailableConsultationSlotsResponse{
		ConsultationSlots: lo.Map(slots, func(slot storage.ConsultationSlot, _ int,
		) *desc.ListAvailableConsultationSlotsResponse_ConsultationSlot {
			return &desc.ListAvailableConsultationSlotsResponse_ConsultationSlot{
				Id:       slot.ID,
				FromTime: timestamppb.New(slot.FromTime),
				ToTime:   timestamppb.New(slot.ToTime),
			}
		}),
	}, nil
}

// CreateConsultationAppointment implements the consultation appointment creation endpoint.
func (s *Service) CreateConsultationAppointment(ctx context.Context, req *desc.CreateConsultationAppointmentRequest) (*desc.CreateConsultationAppointmentResponse, error) {
	session, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	businessUser, err := s.db.GetBusinessUser(ctx, session.AccountID)
	if err != nil {
		s.logger.Error("failed to get business user during consultation appointment creation",
			"account_id", session.AccountID,
			"error", err,
		)
		return nil, errInternal
	}

	inspector, err := s.db.CreateConsultationAppointment(ctx, req.TopicId, req.SlotId, businessUser.ID)
	if errors.Is(err, storage.ErrConsultationSlotExhausted) {
		return nil, errSlotAlreadyTaken
	} else if err != nil {
		s.logger.Error("failed to create consultation appointment in storage",
			"topic_id", req.TopicId,
			"slot_id", req.SlotId,
			"business_user_id", businessUser.ID,
			"error", err,
		)
		return nil, errInternal
	}

	return &desc.CreateConsultationAppointmentResponse{
		Inspector: &desc.AuthorityUser{
			FirstName: inspector.FirstName,
			LastName:  inspector.LastName,
		},
	}, nil
}

// CancelConsultationAppointment implements the consultation appointment cancelation endpoint.
func (s *Service) CancelConsultationAppointment(ctx context.Context, req *desc.CancelConsultationAppointmentRequest) (*emptypb.Empty, error) {
	session, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness)
	if !authorized {
		return nil, errUnauthorized
	}

	businessUser, err := s.db.GetBusinessUser(ctx, session.AccountID)
	if err != nil {
		s.logger.Error("failed to get business user during consultation appointment cancelation",
			"account_id", session.AccountID,
			"error", err,
		)
		return nil, errInternal
	}

	if err := s.db.CancelConsultationAppointment(ctx, req.Id, businessUser.ID); errors.Is(err, storage.ErrNotFound) {
		return nil, errConsultationNotFound
	} else if err != nil {
		s.logger.Error("failed to mark consultation appointment as canceled in storage",
			"consultation_id", req.Id,
			"business_user_id", businessUser.ID,
			"error", err,
		)
		return nil, errInternal
	}

	return &emptypb.Empty{}, nil
}

// ListConsultationAppointments implements the appointment listing endpoint for both business and authority users.
func (s *Service) ListConsultationAppointments(ctx context.Context, _ *emptypb.Empty) (*desc.ListConsultationAppointmentsResponse, error) {
	session, authorized := s.authorizeSession(ctx)
	if !authorized {
		return nil, errUnauthorized
	}

	var err error
	var appointments []storage.ConsultationAppointment
	if session.AccountType == storage.AccountTypeBusiness {
		appointments, err = s.db.ListBusinessConsultationAppointments(ctx, session.AccountID)
	} else if session.AccountType == storage.AccountTypeAuthority {
		appointments, err = s.db.ListInspectorConsultationAppointments(ctx, session.AccountID)
	}

	if err != nil {
		s.logger.Error("failed to list user appointments",
			"account_type", session.AccountType,
			"account_id", session.AccountID,
			"error", err,
		)
		return nil, errInternal
	}

	return &desc.ListConsultationAppointmentsResponse{
		AppointmentInfo: lo.Map(appointments, func(appointment storage.ConsultationAppointment, _ int,
		) *desc.ListConsultationAppointmentsResponse_AppointmentInfo {
			return &desc.ListConsultationAppointmentsResponse_AppointmentInfo{
				Id:       appointment.ID,
				Topic:    appointment.Topic.Name,
				FromTime: timestamppb.New(appointment.Slot.FromTime),
				ToTime:   timestamppb.New(appointment.Slot.ToTime),
				BusinessUser: &desc.BusinessUser{
					FirstName:      appointment.BusinessUser.FirstName,
					PatronymicName: appointment.BusinessUser.PatronymicName,
					LastName:       appointment.BusinessUser.LastName,
					Sex:            personSexFromStorage[appointment.BusinessUser.Sex],
					BirthDate:      timestamppb.New(appointment.BusinessUser.BirthDate),
					BusinessName:   appointment.BusinessUser.BusinessName,
					PhoneNumber:    appointment.BusinessUser.PhoneNumber,
				},
				AuthorityUser: &desc.AuthorityUser{
					FirstName:     appointment.InspectorUser.FirstName,
					LastName:      appointment.InspectorUser.LastName,
					AuthorityName: appointment.InspectorUser.Authority.Name,
				},
				Canceled: appointment.CanceledAt != nil,
			}
		}),
	}, nil
}
