package excel

import (
	"fmt"
	"io"
	"log"
	"strings"
	"time"

	"github.com/samber/lo"
	"github.com/xuri/excelize/v2"
)

const (
	// 32MB limit on completely unzipped file size
	unzipSizeLimit = 32 << 20
	// 16MB limit on memory while unzipping
	unzipXMLSizeLimit = 16 << 20
)

var excelizeOptions = excelize.Options{
	UnzipSizeLimit:    unzipSizeLimit,
	UnzipXMLSizeLimit: unzipXMLSizeLimit,
}

type TimeRange struct {
	From time.Time
	To   time.Time
}

// AuthorityInfo contains information about the consultation topics and time slots of a single authority.
type AuthorityInfo struct {
	Name   string
	Topics []string
	Slots  []TimeRange
}

// ParseTimeSlotFile parses a time slot XLSX sheet containing information about the
// available authorities and their consultation topics and slots.
func ParseTimeSlotFile(r io.Reader) ([]*AuthorityInfo, error) {
	f, err := excelize.OpenReader(r, excelizeOptions)
	if err != nil {
		return nil, fmt.Errorf("opening reader: %w", err)
	}

	defer func() {
		if err := f.Close(); err != nil {
			log.Printf("failed to close excel file: %v", err)
		}
	}()

	var authorityInfos []*AuthorityInfo

	// Skip the first sheet because it contains information about the spreadsheet
	for i, sheet := range f.GetSheetList() {
		if i == 0 {
			continue
		}

		info, err := parseTimeSlotSheet(f, sheet)
		if err != nil {
			return nil, err
		}

		authorityInfos = append(authorityInfos, info)
	}

	return authorityInfos, nil
}

func parseTimeSlotSheet(f *excelize.File, sheet string) (_ *AuthorityInfo, err error) {
	rows, err := f.Rows(sheet)
	if err != nil {
		//lint:ignore ST1005 Ошибка для пользователя
		return nil, fmt.Errorf("Не удалось прочитать строки листа %s", sheet)
	}

	info := new(AuthorityInfo)

	// Parse authority name
	if !rows.Next() {
		//lint:ignore ST1005 Ошибка для пользователя
		return nil, fmt.Errorf("Лист %s не содержит ни одной строки", sheet)
	} else if info.Name, _, err = parseInfoRow(rows); err != nil {
		//lint:ignore ST1005 Ошибка для пользователя
		return nil, fmt.Errorf("Первая строка листа %s не содержит корректное название КНО (%s)", sheet, err)
	}

	// Parse consultation topics
	rowIndex := 2
	for ; rows.Next(); rowIndex++ {
		topic, ok, err := parseInfoRow(rows)
		if ok && err != nil {
			// End of topics list
			break
		} else if err != nil {
			return nil, fmt.Errorf(
				"%d строка листа %s не содержит корректное название темы консультирования (%s)",
				rowIndex,
				sheet,
				err)
		}

		info.Topics = append(info.Topics, topic)
	}

	if len(info.Topics) < 1 {
		//lint:ignore ST1005 Ошибка для пользователя
		return nil, fmt.Errorf("Отсутствуют темы консультаций на листе %s", sheet)
	}

	// Parse time slots
	for ; rows.Next(); rowIndex++ {
		columns, err := rows.Columns(excelizeOptions)
		if err != nil {
			//lint:ignore ST1005 Ошибка для пользователя
			return nil, fmt.Errorf("Ошибка чтения %d строки расписания листа %s", rowIndex, sheet)
		} else if len(columns) == 0 {
			continue
		}

		// Iterate over the columns searching for a valid date and then a valid time range
		for i := 0; i < len(columns); i++ {
			t, err := parseDateCell(columns[i])
			if err != nil {
				continue
			}

			if i == len(columns)-1 {
				//lint:ignore ST1005 Ошибка для пользователя
				return nil, fmt.Errorf(
					"На %d строке расписания листа %s отсутствует временной диапазон для слота на дату %s",
					rowIndex,
					sheet,
					t.String(),
				)
			}

			i++
			fromHHMM, toHHMM, err := parseTimeRange(sheet, rowIndex, t, columns[i])
			if err != nil {
				return nil, err
			}

			info.Slots = append(info.Slots, TimeRange{
				From: dateWithTime(t, fromHHMM),
				To:   dateWithTime(t, toHHMM),
			})
		}
	}

	if len(info.Slots) == 0 {
		//lint:ignore ST1005 Ошибка для пользователя
		return nil, fmt.Errorf("Отсутствуют слоты консультаций на листе %s", sheet)
	}

	return info, nil
}

// parseDateCell parses a date in two possible formats (thank you Excel)
func parseDateCell(value string) (time.Time, error) {
	value = strings.TrimSpace(value)

	t, err := time.Parse("2/1/2006", value)
	if err == nil {
		return t, nil
	}

	return time.Parse("01-02-06", value)
}

func parseTimeRange(sheet string, rowIndex int, date time.Time, value string) (time.Time, time.Time, error) {
	parts := strings.Split(value, "-")
	if len(parts) != 2 {
		//lint:ignore ST1005 Ошибка для пользователя
		return time.Time{}, time.Time{}, fmt.Errorf(
			"Некорректное время %q для даты %s на %d строке листа %s",
			value,
			date.String(),
			rowIndex,
			sheet,
		)
	}

	from, err := parseTimeHHMM(strings.TrimSpace(parts[0]))
	if err != nil {
		//lint:ignore ST1005 Ошибка для пользователя
		return time.Time{}, time.Time{}, fmt.Errorf(
			"Некорректное время начала консультации %s для даты %s на %d строке листа %s",
			parts[0],
			date.String(),
			rowIndex,
			sheet,
		)
	}

	to, err := parseTimeHHMM(strings.TrimSpace(parts[1]))
	if err != nil {
		//lint:ignore ST1005 Ошибка для пользователя
		return time.Time{}, time.Time{}, fmt.Errorf(
			"Некорректное время завершения консультации %s для даты %s на %d строке листа %s",
			parts[1],
			date.String(),
			rowIndex,
			sheet,
		)
	}

	return from, to, nil
}

func parseTimeHHMM(value string) (time.Time, error) {
	return time.Parse("15:04", value)
}

func dateWithTime(date, hhmm time.Time) time.Time {
	return date.Add(time.Duration(hhmm.Hour())*time.Hour + time.Duration(hhmm.Minute())*time.Minute)
}

func parseInfoRow(rows *excelize.Rows) (_ string, ok bool, err error) {
	columns, err := rows.Columns(excelizeOptions)
	if err != nil {
		return "", false, fmt.Errorf("ошибка чтения столбцов")
	}

	// Filter out empty columns to avoid confusing users about superfluous columns which aren't even visible
	columns = lo.Filter(columns, func(s string, _ int) bool {
		return len(s) > 0
	})

	if len(columns) != 1 {
		return "", true, fmt.Errorf("%d непустых столбцов вместо одного", len(columns))
	}

	return strings.TrimSpace(columns[0]), true, nil
}
