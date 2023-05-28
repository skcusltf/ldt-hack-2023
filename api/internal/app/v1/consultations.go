package app

import (
	"context"
	"sort"

	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"github.com/samber/lo"
	"google.golang.org/protobuf/types/known/emptypb"
)

// ListConsultationTopics implements the consultation topic listing endpoint.
func (s *Service) ListConsultationTopics(ctx context.Context, _ *emptypb.Empty) (*desc.ListConsultationTopicsResponse, error) {
	if _, authorized := s.authorizeSession(ctx, storage.AccountTypeBusiness); !authorized {
		return nil, errUnauthorized
	}

	topics, err := s.db.ListConsultationTopics(ctx)
	if err != nil {
		s.logger.Info("failed to list consultation topics", "error", err)
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
