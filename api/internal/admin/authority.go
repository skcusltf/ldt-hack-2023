package admin

import (
	"context"
	"net/http"
	"strconv"

	"ldt-hack/api/internal/crypto"
	"ldt-hack/api/internal/excel"
	"ldt-hack/api/internal/storage"

	"github.com/gin-gonic/gin"
	"github.com/samber/lo"
	"github.com/uptrace/bun"
)

func (s *Service) authorityInfoHandler(c *gin.Context) {
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
		c.AbortWithStatusJSON(http.StatusBadRequest, apiError{err.Error()})
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

func (s *Service) listAuthoritiesHandler(c *gin.Context) {
	authorities, err := s.db.ListAuthorities(c)
	if err != nil {
		s.logger.Error("failed to list authorities in database", "error", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.JSON(http.StatusOK, lo.Map(authorities, func(a storage.Authority, _ int) authority {
		return authority{
			ID:   a.ID,
			Name: a.Name,
		}
	}))
}

func (s *Service) createInspectorHandler(c *gin.Context) {
	var req createInspectorRequest
	if err := c.Bind(&req); err != nil {
		return
	}

	if req.Email == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, apiError{"Необходимо указать почту для регистрации инспектора"})
		return
	} else if len(req.Password) < 3 || len(req.Password) > 50 {
		c.AbortWithStatusJSON(http.StatusBadRequest, apiError{"Пароль инспектора должен быть не короче 3 и не длиннее 50 символов"})
		return
	} else if req.FirstName == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, apiError{"Необходимо указать имя инспектора"})
		return
	} else if req.LastName == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, apiError{"Необходимо указать фамилию инспектора"})
		return
	}

	authorityID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	passwordHash, err := crypto.HashPassword(req.Password)
	if err != nil {
		s.logger.Error("failed to hash password", "error", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if err := s.db.CreateInspectorUser(c, req.Email, passwordHash, storage.InspectorUser{
		AuthorityID: authorityID,
		FirstName:   req.FirstName,
		LastName:    req.LastName,
	}); err != nil {
		s.logger.Error("failed to create inspector in database", "error", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.Status(http.StatusCreated)
}
