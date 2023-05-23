package app

import (
	desc "ldt-hack/api/internal/pb/app/v1"
	"ldt-hack/api/internal/storage"

	"github.com/samber/lo"
)

var personSexToStorage = map[desc.PersonSex]storage.PersonSex{
	desc.PersonSex_PERSON_SEX_MALE:   storage.PersonSexMale,
	desc.PersonSex_PERSON_SEX_FEMALE: storage.PersonSexFemale,
}

var personSexFromStorage = lo.Invert(personSexToStorage)

var sessionUserToStorage = map[desc.CreateSessionRequest_SessionUser]storage.AccountType{
	desc.CreateSessionRequest_SESSION_USER_BUSINESS:  storage.AccountTypeBusiness,
	desc.CreateSessionRequest_SESSION_USER_AUTHORITY: storage.AccountTypeAuthority,
}
