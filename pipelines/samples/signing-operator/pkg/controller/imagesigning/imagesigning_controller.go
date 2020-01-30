package imagesigning

import (
	"bytes"
	"context"
	"fmt"
	"reflect"

	"github.com/go-logr/logr"
	"golang.org/x/crypto/openpgp"
	"golang.org/x/crypto/openpgp/armor"
	"golang.org/x/crypto/openpgp/packet"

	securityv1alpha1 "github.com/kabanero-io/kabanero-security/signing-operator/pkg/apis/security/v1alpha1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/event"
	"sigs.k8s.io/controller-runtime/pkg/predicate"

	"sigs.k8s.io/controller-runtime/pkg/handler"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	"sigs.k8s.io/controller-runtime/pkg/source"
)

var log = logf.Log.WithName("controller_imagesigning")

const (
	secretName    = "signature-secret-key"
	secretKeyName = "secret.asc"
)

/**
* USER ACTION REQUIRED: This is a scaffold file intended for the user to modify with their own Controller
* business logic.  Delete these comments after modifying this file.*
 */

// Add creates a new ImageSigning Controller and adds it to the Manager. The Manager will set fields on the Controller
// and Start it when the Manager is Started.
func Add(mgr manager.Manager) error {
	return add(mgr, newReconciler(mgr))
}

// newReconciler returns a new reconcile.Reconciler
func newReconciler(mgr manager.Manager) reconcile.Reconciler {
	return &ReconcileImageSigning{client: mgr.GetClient(), scheme: mgr.GetScheme()}
}

// add adds a new Controller to mgr with r as the reconcile.Reconciler
func add(mgr manager.Manager, r reconcile.Reconciler) error {
	// Create a new controller
	c, err := controller.New("imagesigning-controller", mgr, controller.Options{Reconciler: r})
	if err != nil {
		return err
	}

	// Create crd predicate to reduce unnecessary event handling.
	crdPred := predicate.Funcs{
		CreateFunc: func(e event.CreateEvent) bool {
			log.Info("CRD CreateEvent")
			return true
		},
		GenericFunc: func(e event.GenericEvent) bool {
			log.Info("CRD GenericEvent")
			return false
		},
		UpdateFunc: func(e event.UpdateEvent) bool {
			result := !reflect.DeepEqual(e.ObjectOld, e.ObjectNew)
			if result {
				log.Info("CRD UpdateEvent : true")
			} else {
				log.Info("CRD UpdateEvent : false")
			}
			return !reflect.DeepEqual(e.ObjectOld, e.ObjectNew)
		},
	}
	// Watch for changes to primary resource ImageSigning
	err = c.Watch(&source.Kind{Type: &securityv1alpha1.ImageSigning{}}, &handler.EnqueueRequestForObject{}, crdPred)
	if err != nil {
		return err
	}

	// Create secret predicate to reduce unnecessary event handling.
	sPred := predicate.Funcs{
		CreateFunc: func(e event.CreateEvent) bool {
			log.Info("Secret CreateEvent returning false")
			return false
		},
		GenericFunc: func(e event.GenericEvent) bool {
			log.Info("Secret GenericEvent returning false")
			return false
		},
		DeleteFunc: func(e event.DeleteEvent) bool {
			if e.Meta.GetName() == secretName {
				log.Info("Secret DeleteEvent returning true")
				return true
			}
			log.Info("Secret DeleteEvent returning false")
			return false
		},
		UpdateFunc: func(e event.UpdateEvent) bool {
			log.Info("Secret UpdateEvent : false")
			return false
		},
	}

	// Watch for changes to the secrt which is not owned by ImageSigning.
	// If the secret which is not owned by ImageSigning CR, a new secret is
	// generated.
	err = c.Watch(&source.Kind{Type: &corev1.Secret{}}, &handler.EnqueueRequestForObject{}, sPred)
	if err != nil {
		return err
	}

	return nil
}

// blank assignment to verify that ReconcileImageSigning implements reconcile.Reconciler
var _ reconcile.Reconciler = &ReconcileImageSigning{}

// ReconcileImageSigning reconciles a ImageSigning object
type ReconcileImageSigning struct {
	// This client, initialized using mgr.Client() above, is a split client
	// that reads objects from the cache and writes to the apiserver
	client client.Client
	scheme *runtime.Scheme
}

// Reconcile reads that state of the cluster for a ImageSigning object and makes changes based on the state read
// and what is in the ImageSigning.Spec
// Note:
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.
func (r *ReconcileImageSigning) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name)
	reqLogger.Info("Reconciling ImageSigning")

	//
	// get custom resource
	cr, err := findCR(r, request.Namespace)
	if err != nil {
		// Error reading the object - requeue the request.
		reqLogger.Error(err, "Failed to get ImageSigning resource.")
		return reconcile.Result{}, err
	}
	if cr == nil {
		reqLogger.Info("ImageSigning CR is not found. Do nothing.")
		return reconcile.Result{}, nil
	}

	// Find existing imagesigning secret
	secret, err := findSecret(r, request.Namespace)
	if err != nil {
		reqLogger.Error(err, "Failed to get ImageSigning secret.")
		return reconcile.Result{}, err
	}
	if secret != nil {
		reqLogger.Info("found ImageSigning secret. Do nothing")
		return reconcile.Result{}, nil
	}

	if !cr.Status.Generated {
		// create Entity from the public key.
		err = generateKeyPair(&cr.Spec, &cr.Status, reqLogger)
		if err != nil {
			return reconcile.Result{}, err
		}
		// update status since a new keypair has generated.
		err = r.client.Status().Update(context.TODO(), cr)
		if err != nil {
			reqLogger.Error(err, "Failed to update ImageSigning status.")
			return reconcile.Result{}, err
		}
	}
	// create secret
	if cr.Status.Generated {
		desired, err := createSecret(cr.ObjectMeta.Namespace, cr.Status.SecretKey)
		reqLogger.Info("Create a new secret")
		controllerutil.SetControllerReference(cr, desired, r.scheme)
		err = r.client.Create(context.TODO(), desired)
		if err != nil {
			reqLogger.Error(err, "Failed to create or update a new ImageSigning secret.")
			return reconcile.Result{}, err
		}
	}

	return reconcile.Result{}, nil
}

func findSecret(r *ReconcileImageSigning, ns string) (*corev1.Secret, error) {
	sl := corev1.SecretList{}
	err := r.client.List(context.Background(), &sl, client.InNamespace(ns))
	if err != nil {
		return nil, err
	}
	for _, _s := range sl.Items {
		if _s.ObjectMeta.Name == secretName {
			return &_s, nil
		}
	}
	return nil, nil
}
func findCR(r *ReconcileImageSigning, ns string) (*securityv1alpha1.ImageSigning, error) {
	cr := securityv1alpha1.ImageSigningList{}
	err := r.client.List(context.Background(), &cr, client.InNamespace(ns))
	if err != nil {
		return nil, err
	}
	for _, _cr := range cr.Items {
		return &_cr, nil
	}
	return nil, nil
}

//TODO: not used. delete later.
// By convention, this takes the form "Full Name (Comment) <email@example.com>"
func getIdentity(secret *corev1.Secret) (string, error) {
	if secret == nil {
		return "", nil
	}
	pk := secret.Data[secretKeyName]
	block, err := armor.Decode(bytes.NewReader(pk))
	if err != nil {
		return "", err
	}
	entity, err := openpgp.ReadEntity(packet.NewReader(block.Body))
	if err != nil {
		return "", err
	}
	var id string
	for i := range entity.Identities {
		id = i
		break
	}
	return id, nil
}

//TODO: not used. delete later.
func getNewIdentity(id *securityv1alpha1.SignatureIdentity) string {
	comment := id.Comment
	if len(comment) > 0 {
		return fmt.Sprintf("%s (%s) <%s>", id.Name, comment, id.Email)
	}
	return fmt.Sprintf("%s <%s>", id.Name, id.Email)

}

// TODO support validating and creating image from supplied public and private key.
// TODO will be deleted
func genKey(id *securityv1alpha1.SignatureIdentity, reqLogger logr.Logger) (*openpgp.Entity, error) {
	name := id.Name
	reqLogger.Info("name is " + name)
	var e *openpgp.Entity
	e, err := openpgp.NewEntity(name, id.Comment, id.Email, nil)
	if err != nil {
		reqLogger.Error(err, "Failed to generate RSA key for signing.")
		return nil, err
	}
	// remove default subkey which is not used.
	e.Subkeys = nil
	return e, nil

}

// generate or copy keypair in the ImageSiginingSpec to ImageSigningStatus
func generateKeyPair(spec *securityv1alpha1.ImageSigningSpec, status *securityv1alpha1.ImageSigningStatus, reqLogger logr.Logger) error {
	if spec.Keypair != nil {
		// if keypair is supplied, validate the keys and set them.
		// TODO: add validation. make sure that nil check is required.
		// err := errors.New("secretKey and publicKey should be set for importing keypair.")
		reqLogger.Info("Importing RSA keypair for image signing.")
		status.PublicKey = spec.Keypair.PublicKey
		status.SecretKey = spec.Keypair.SecretKey
		status.ErrorMessage = ""
		status.Generated = true
		return nil
	}

	if spec.Identity != nil {
		reqLogger.Info("Generating RSA keypair for image signing.")
		var e *openpgp.Entity
		e, err := genKey(spec.Identity, reqLogger)
		if err != nil {
			status.ErrorMessage = err.Error()
			status.Generated = false
			status.PublicKey = ""
			status.SecretKey = ""
			return err
		}
		err = copyToStatus(e, status, reqLogger)
		if err != nil {
			status.ErrorMessage = err.Error()
			status.Generated = false
			status.PublicKey = ""
			status.SecretKey = ""
			return err
		}
		status.ErrorMessage = ""
		status.Generated = true
		return nil
	}
	msg := "There is not sufficient information for generating or importing RSA keypair."
	reqLogger.Info(msg)
	status.ErrorMessage = msg
	status.Generated = false
	return nil
}

func copyToStatus(e *openpgp.Entity, status *securityv1alpha1.ImageSigningStatus, reqLogger logr.Logger) error {
	sbuf := bytes.NewBuffer(nil)
	ws, err := armor.Encode(sbuf, openpgp.PrivateKeyType, nil)
	if err != nil {
		reqLogger.Error(err, "Failed to armor RSA secret key for signing.")
		return err
	}
	err = e.SerializePrivate(ws, nil)
	ws.Close()
	if err != nil {
		reqLogger.Error(err, "Failed to serialize RSA secret key for signing.")
		return err
	}
	status.SecretKey = sbuf.String()

	pbuf := bytes.NewBuffer(nil)
	wp, err := armor.Encode(pbuf, openpgp.PublicKeyType, nil)
	if err != nil {
		reqLogger.Error(err, "Failed to armor RSA public key for signing.")
		return err
	}
	err = e.Serialize(wp)
	wp.Close()
	if err != nil {
		reqLogger.Error(err, "Failed to serialize RSA public key for signing.")
		return err
	}
	status.PublicKey = pbuf.String()
	return nil
}

// create a secret named signature-secret-key which contains two elements.
// secret.asc is a secret key which will be used for signing the images.
// public.crt is an ascii armored public key which can be either imported to pgp keyring
// or set the first base64 encoded part (safe to ignore the 2nd part of base64 encoded string)
// into policy.json file with keyData tag for enforcing image verification.
func createSecret(namespace string, armoredPrivateKey string) (*corev1.Secret, error) {
	m := map[string][]byte{}
	m[secretKeyName] = []byte(armoredPrivateKey)
	return &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{
			Name:      secretName,
			Namespace: namespace,
		},
		Data: m,
	}, nil
}
