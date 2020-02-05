package apis

import (
	"github.com/kabanero-io/kabanero-security/signing-operator/pkg/apis/security/v1alpha1"
)

func init() {
	// Register the types with the Scheme so the components can map objects to GroupVersionKinds and back
	AddToSchemes = append(AddToSchemes, v1alpha1.SchemeBuilder.AddToScheme)
}
