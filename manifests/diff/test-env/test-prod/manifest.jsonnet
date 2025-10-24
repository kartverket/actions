{
  apiVersion: 'skiperator.kartverket.no/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'prod-test',
  },
  spec: {
    image: 'test',
    port: 5000,
  },
}
