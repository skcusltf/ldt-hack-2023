package admin

import (
	"context"
	"net/http"

	"ldt-hack/api/internal/excel"
	"ldt-hack/api/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"github.com/uptrace/bun"
)

func (s *Service) authorityInfoHandler(c *gin.Context) {
	if !s.authorizeSession(c) {
		return
	}

	var req authorityInfoRequest
	if err := c.Bind(&req); err != nil {
		return
	}

	f, err := req.File.Open()
	if err != nil {
		s.logger.Error("failed to open uploaded file", "error", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	authorityInfo, err := excel.ParseTimeSlotFile(f)
	if err != nil {
		s.logger.Info("failed to parse incoming time slot sheet", "error", err)
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	s.db.WithTx(c, false, func(ctx context.Context, tx bun.Tx) error {
		// Create new authorities
		authorities, err := s.db.CreateAuthoritiesTx(ctx, tx, lo.Map(authorityInfo, func(i *excel.AuthorityInfo, _ int) string {
			return i.Name
		}))
		if err != nil {
			return err
		}

		authorityIDByName := lo.Associate(authorities, func(a storage.Authority) (string, int64) {
			return a.Name, a.ID
		})

		// Create new topics
		consultationTopics := lo.FlatMap(authorityInfo, func(i *excel.AuthorityInfo, _ int) []storage.ConsultationTopic {
			return lo.Map(i.Topics, func(s string, _ int) storage.ConsultationTopic {
				return storage.ConsultationTopic{
					AuthorityID: authorityIDByName[i.Name],
					Name:        s,
				}
			})
		})

		if err := s.db.CreateTopicsTx(ctx, tx, consultationTopics); err != nil {
			return err
		}

		// Create new time slots
		consultationSlots := lo.FlatMap(authorityInfo, func(i *excel.AuthorityInfo, _ int) []storage.ConsultationSlot {
			return lo.Map(i.Slots, func(r excel.TimeRange, _ int) storage.ConsultationSlot {
				return storage.ConsultationSlot{
					AuthorityID: authorityIDByName[i.Name],
					FromTime:    r.From,
					ToTime:      r.To,
				}
			})
		})

		if err := s.db.CreateSlotsTx(ctx, tx, consultationSlots); err != nil {
			return err
		}

		return nil
	})
}
