package controller

import (
	"github.com/kabanero-io/kabanero-security/signing-operator/pkg/controller/imagesigning"
)

func init() {
	// AddToManagerFuncs is a list of functions to create controllers and add them to a manager.
	AddToManagerFuncs = append(AddToManagerFuncs, imagesigning.Add)
}
