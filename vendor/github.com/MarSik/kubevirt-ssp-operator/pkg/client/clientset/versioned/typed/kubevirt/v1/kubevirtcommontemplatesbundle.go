/*
Copyright The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code generated by client-gen. DO NOT EDIT.

package v1

import (
	v1 "github.com/MarSik/kubevirt-ssp-operator/pkg/apis/kubevirt/v1"
	scheme "github.com/MarSik/kubevirt-ssp-operator/pkg/client/clientset/versioned/scheme"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	rest "k8s.io/client-go/rest"
)

// KubevirtCommonTemplatesBundlesGetter has a method to return a KubevirtCommonTemplatesBundleInterface.
// A group's client should implement this interface.
type KubevirtCommonTemplatesBundlesGetter interface {
	KubevirtCommonTemplatesBundles(namespace string) KubevirtCommonTemplatesBundleInterface
}

// KubevirtCommonTemplatesBundleInterface has methods to work with KubevirtCommonTemplatesBundle resources.
type KubevirtCommonTemplatesBundleInterface interface {
	Create(*v1.KubevirtCommonTemplatesBundle) (*v1.KubevirtCommonTemplatesBundle, error)
	Update(*v1.KubevirtCommonTemplatesBundle) (*v1.KubevirtCommonTemplatesBundle, error)
	UpdateStatus(*v1.KubevirtCommonTemplatesBundle) (*v1.KubevirtCommonTemplatesBundle, error)
	Delete(name string, options *metav1.DeleteOptions) error
	DeleteCollection(options *metav1.DeleteOptions, listOptions metav1.ListOptions) error
	Get(name string, options metav1.GetOptions) (*v1.KubevirtCommonTemplatesBundle, error)
	List(opts metav1.ListOptions) (*v1.KubevirtCommonTemplatesBundleList, error)
	Watch(opts metav1.ListOptions) (watch.Interface, error)
	Patch(name string, pt types.PatchType, data []byte, subresources ...string) (result *v1.KubevirtCommonTemplatesBundle, err error)
	KubevirtCommonTemplatesBundleExpansion
}

// kubevirtCommonTemplatesBundles implements KubevirtCommonTemplatesBundleInterface
type kubevirtCommonTemplatesBundles struct {
	client rest.Interface
	ns     string
}

// newKubevirtCommonTemplatesBundles returns a KubevirtCommonTemplatesBundles
func newKubevirtCommonTemplatesBundles(c *KubevirtV1Client, namespace string) *kubevirtCommonTemplatesBundles {
	return &kubevirtCommonTemplatesBundles{
		client: c.RESTClient(),
		ns:     namespace,
	}
}

// Get takes name of the kubevirtCommonTemplatesBundle, and returns the corresponding kubevirtCommonTemplatesBundle object, and an error if there is any.
func (c *kubevirtCommonTemplatesBundles) Get(name string, options metav1.GetOptions) (result *v1.KubevirtCommonTemplatesBundle, err error) {
	result = &v1.KubevirtCommonTemplatesBundle{}
	err = c.client.Get().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		Name(name).
		VersionedParams(&options, scheme.ParameterCodec).
		Do().
		Into(result)
	return
}

// List takes label and field selectors, and returns the list of KubevirtCommonTemplatesBundles that match those selectors.
func (c *kubevirtCommonTemplatesBundles) List(opts metav1.ListOptions) (result *v1.KubevirtCommonTemplatesBundleList, err error) {
	result = &v1.KubevirtCommonTemplatesBundleList{}
	err = c.client.Get().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		VersionedParams(&opts, scheme.ParameterCodec).
		Do().
		Into(result)
	return
}

// Watch returns a watch.Interface that watches the requested kubevirtCommonTemplatesBundles.
func (c *kubevirtCommonTemplatesBundles) Watch(opts metav1.ListOptions) (watch.Interface, error) {
	opts.Watch = true
	return c.client.Get().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		VersionedParams(&opts, scheme.ParameterCodec).
		Watch()
}

// Create takes the representation of a kubevirtCommonTemplatesBundle and creates it.  Returns the server's representation of the kubevirtCommonTemplatesBundle, and an error, if there is any.
func (c *kubevirtCommonTemplatesBundles) Create(kubevirtCommonTemplatesBundle *v1.KubevirtCommonTemplatesBundle) (result *v1.KubevirtCommonTemplatesBundle, err error) {
	result = &v1.KubevirtCommonTemplatesBundle{}
	err = c.client.Post().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		Body(kubevirtCommonTemplatesBundle).
		Do().
		Into(result)
	return
}

// Update takes the representation of a kubevirtCommonTemplatesBundle and updates it. Returns the server's representation of the kubevirtCommonTemplatesBundle, and an error, if there is any.
func (c *kubevirtCommonTemplatesBundles) Update(kubevirtCommonTemplatesBundle *v1.KubevirtCommonTemplatesBundle) (result *v1.KubevirtCommonTemplatesBundle, err error) {
	result = &v1.KubevirtCommonTemplatesBundle{}
	err = c.client.Put().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		Name(kubevirtCommonTemplatesBundle.Name).
		Body(kubevirtCommonTemplatesBundle).
		Do().
		Into(result)
	return
}

// UpdateStatus was generated because the type contains a Status member.
// Add a +genclient:noStatus comment above the type to avoid generating UpdateStatus().

func (c *kubevirtCommonTemplatesBundles) UpdateStatus(kubevirtCommonTemplatesBundle *v1.KubevirtCommonTemplatesBundle) (result *v1.KubevirtCommonTemplatesBundle, err error) {
	result = &v1.KubevirtCommonTemplatesBundle{}
	err = c.client.Put().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		Name(kubevirtCommonTemplatesBundle.Name).
		SubResource("status").
		Body(kubevirtCommonTemplatesBundle).
		Do().
		Into(result)
	return
}

// Delete takes name of the kubevirtCommonTemplatesBundle and deletes it. Returns an error if one occurs.
func (c *kubevirtCommonTemplatesBundles) Delete(name string, options *metav1.DeleteOptions) error {
	return c.client.Delete().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		Name(name).
		Body(options).
		Do().
		Error()
}

// DeleteCollection deletes a collection of objects.
func (c *kubevirtCommonTemplatesBundles) DeleteCollection(options *metav1.DeleteOptions, listOptions metav1.ListOptions) error {
	return c.client.Delete().
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		VersionedParams(&listOptions, scheme.ParameterCodec).
		Body(options).
		Do().
		Error()
}

// Patch applies the patch and returns the patched kubevirtCommonTemplatesBundle.
func (c *kubevirtCommonTemplatesBundles) Patch(name string, pt types.PatchType, data []byte, subresources ...string) (result *v1.KubevirtCommonTemplatesBundle, err error) {
	result = &v1.KubevirtCommonTemplatesBundle{}
	err = c.client.Patch(pt).
		Namespace(c.ns).
		Resource("kubevirtcommontemplatesbundles").
		SubResource(subresources...).
		Name(name).
		Body(data).
		Do().
		Into(result)
	return
}